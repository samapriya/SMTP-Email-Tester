#!/bin/bash

# Create directories
mkdir -p templates

# Create app.py file
cat > app.py << 'EOF'
from flask import Flask, request, render_template, jsonify
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.route('/')
def index():
    return render_template('email_form.html')

@app.route('/send_email', methods=['POST'])
def send_email():
    try:
        # Get form data
        mail_driver = request.form.get('mailDriver')
        mail_host = request.form.get('mailHost')
        mail_username = request.form.get('mailUsername')
        mail_password = request.form.get('mailPassword')
        mail_port = int(request.form.get('mailPort'))
        mail_encryption = request.form.get('mailEncryption')
        from_mail_address = request.form.get('fromMailAddress')
        from_mail_name = request.form.get('fromMailName')
        to_email = request.form.get('toEmail')
        subject = request.form.get('subject')
        message_text = request.form.get('message')
        
        # Log connection attempt (without exposing password)
        logging.info(f"Attempting to connect to {mail_host}:{mail_port} with encryption {mail_encryption}")
        
        # Create email
        message = MIMEMultipart('alternative')
        message["Subject"] = subject
        message["From"] = f"{from_mail_name} <{from_mail_address}>"
        message["To"] = to_email
        
        # Create the plain-text and HTML version of your message
        text = message_text
        html = f"""
        <html>
          <body>
            <p>{message_text}</p>
          </body>
        </html>
        """
        
        # Turn these into MIMEText objects
        part1 = MIMEText(text, "plain")
        part2 = MIMEText(html, "html")
        
        # Add parts to MIMEMultipart message
        message.attach(part1)
        message.attach(part2)
        
        # Create connection based on encryption method
        if mail_encryption == 'ssl':
            logging.info("Using SSL encryption")
            context = ssl.create_default_context()
            try:
                server = smtplib.SMTP_SSL(mail_host, mail_port, context=context, timeout=10)
                server.set_debuglevel(1)  # Enable debugging to see the SMTP conversation
            except Exception as e:
                logging.error(f"SSL Connection error: {str(e)}")
                return jsonify({"success": False, "message": f"Error connecting to mail server: {str(e)}"})
        elif mail_encryption == 'tls':
            logging.info("Using TLS encryption")
            try:
                server = smtplib.SMTP(mail_host, mail_port, timeout=10)
                server.set_debuglevel(1)  # Enable debugging
                context = ssl.create_default_context()
                server.starttls(context=context)
            except Exception as e:
                logging.error(f"TLS Connection error: {str(e)}")
                return jsonify({"success": False, "message": f"Error establishing TLS connection: {str(e)}"})
        else:
            logging.info("Using plain text connection (no encryption)")
            try:
                server = smtplib.SMTP(mail_host, mail_port, timeout=10)
                server.set_debuglevel(1)  # Enable debugging
            except Exception as e:
                logging.error(f"Plain connection error: {str(e)}")
                return jsonify({"success": False, "message": f"Error connecting to mail server: {str(e)}"})
        
        # Authenticate if credentials provided
        if mail_username and mail_password:
            try:
                server.login(mail_username, mail_password)
                logging.info("Login successful")
            except Exception as e:
                logging.error(f"Authentication error: {str(e)}")
                server.quit()
                return jsonify({"success": False, "message": f"Authentication failed: {str(e)}"})
        
        # Send email
        try:
            server.sendmail(from_mail_address, to_email, message.as_string())
            logging.info(f"Email sent successfully to {to_email}")
            server.quit()
            return jsonify({"success": True, "message": "Email sent successfully!"})
        except Exception as e:
            logging.error(f"Error sending email: {str(e)}")
            server.quit()
            return jsonify({"success": False, "message": f"Error sending email: {str(e)}"})
        
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return jsonify({"success": False, "message": f"Unexpected error: {str(e)}"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8292, debug=False)
EOF

# Create HTML template
cat > templates/email_form.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMTP Email Tester</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            padding: 25px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
            text-align: center;
        }
        h2 {
            color: #555;
            margin-top: 30px;
            margin-bottom: 20px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input, select, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
        }
        .required:after {
            content: " *";
            color: red;
        }
        button {
            background-color: #4285f4;
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            display: block;
            width: 100%;
            transition: background-color 0.2s;
        }
        button:hover {
            background-color: #3367d6;
        }
        .result {
            margin-top: 20px;
            padding: 15px;
            border-radius: 4px;
            display: none;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .loading {
            text-align: center;
            display: none;
            margin-top: 20px;
        }
        .spinner {
            border: 4px solid rgba(0, 0, 0, 0.1);
            border-radius: 50%;
            border-top: 4px solid #3498db;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        #testSection {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
        }
        .toggle-manual {
            text-align: right;
            margin: -10px 0 15px;
        }
        .toggle-manual button {
            width: auto;
            padding: 5px 10px;
            font-size: 14px;
            background-color: #f0f0f0;
            color: #333;
        }
        .toggle-manual button:hover {
            background-color: #e0e0e0;
        }
        .info-icon {
            display: inline-block;
            width: 16px;
            height: 16px;
            background-color: #4285f4;
            color: white;
            border-radius: 50%;
            text-align: center;
            line-height: 16px;
            font-size: 12px;
            margin-left: 5px;
            cursor: help;
        }
        .tooltip {
            position: relative;
            display: inline-block;
        }
        .tooltip .tooltiptext {
            visibility: hidden;
            width: 250px;
            background-color: #555;
            color: #fff;
            text-align: left;
            border-radius: 6px;
            padding: 10px;
            position: absolute;
            z-index: 1;
            bottom: 125%;
            left: 50%;
            margin-left: -125px;
            opacity: 0;
            transition: opacity 0.3s;
            font-weight: normal;
            font-size: 14px;
            line-height: 1.4;
        }
        .tooltip:hover .tooltiptext {
            visibility: visible;
            opacity: 1;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>SMTP Email Tester</h1>
        
        <form id="emailForm">
            <div class="form-group">
                <label class="required" for="mailProvider">Email Provider</label>
                <select id="mailProvider" name="mailProvider" required>
                    <option value="custom">Custom SMTP Server</option>
                    <option value="gmail">Gmail</option>
                    <option value="outlook">Outlook.com</option>
                    <option value="office365">Office365</option>
                    <option value="yahoo">Yahoo Mail</option>
                    <option value="yahooplus">Yahoo Mail Plus</option>
                    <option value="yahoouk">Yahoo UK</option>
                    <option value="hotmail">Hotmail</option>
                    <option value="zoho">Zoho Mail</option>
                    <option value="gmx">GMX.com</option>
                    <option value="mailcom">Mail.com</option>
                    <option value="aol">AOL</option>
                    <option value="comcast">Comcast</option>
                    <option value="verizon">Verizon</option>
                    <option value="att">AT&T</option>
                    <option value="btinternet">BT Internet</option>
                    <option value="orange">Orange</option>
                </select>
            </div>
            
            <div class="toggle-manual">
                <button type="button" id="toggleManual">Toggle Manual Configuration</button>
            </div>
            
            <div id="manualConfig">
                <div class="form-group">
                    <label class="required" for="mailDriver">Mail Driver</label>
                    <select id="mailDriver" name="mailDriver" required>
                        <option value="smtp" selected>smtp</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label class="required tooltip" for="mailHost">
                        Mail Host
                        <span class="info-icon">i</span>
                        <span class="tooltiptext">The SMTP server address (e.g., smtp.gmail.com)</span>
                    </label>
                    <input type="text" id="mailHost" name="mailHost" required>
                </div>
                
                <div class="form-group">
                    <label class="required tooltip" for="mailPort">
                        Mail Port
                        <span class="info-icon">i</span>
                        <span class="tooltiptext">Common ports:<br>25: Standard SMTP (often blocked)<br>465: SSL encryption<br>587: TLS encryption</span>
                    </label>
                    <select id="mailPort" name="mailPort" required>
                        <option value="25">25 (Standard SMTP)</option>
                        <option value="465" selected>465 (SSL)</option>
                        <option value="587">587 (TLS/StartTLS)</option>
                        <option value="2525">2525 (Alternative)</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label class="required tooltip" for="mailEncryption">
                        Mail Encryption
                        <span class="info-icon">i</span>
                        <span class="tooltiptext">SSL: Full encryption from start<br>TLS/StartTLS: Upgrades connection to secure<br>None: Unencrypted (not recommended)</span>
                    </label>
                    <select id="mailEncryption" name="mailEncryption" required>
                        <option value="ssl" selected>SSL</option>
                        <option value="tls">TLS/StartTLS</option>
                        <option value="none">None</option>
                    </select>
                </div>
            </div>
            
            <div class="form-group">
                <label class="tooltip" for="mailUsername">
                    Mail Username
                    <span class="info-icon">i</span>
                    <span class="tooltiptext">Your full email address</span>
                </label>
                <input type="email" id="mailUsername" name="mailUsername" placeholder="your.email@provider.com">
            </div>
            
            <div class="form-group">
                <label class="tooltip" for="mailPassword">
                    Mail Password
                    <span class="info-icon">i</span>
                    <span class="tooltiptext">For Gmail/Outlook, use an app password instead of your regular password</span>
                </label>
                <input type="password" id="mailPassword" name="mailPassword" placeholder="Your password or app password">
            </div>
            
            <div class="form-group">
                <label class="required" for="fromMailAddress">From Mail Address</label>
                <input type="email" id="fromMailAddress" name="fromMailAddress" placeholder="sender@example.com" required>
            </div>
            
            <div class="form-group">
                <label class="required" for="fromMailName">From Mail Name</label>
                <input type="text" id="fromMailName" name="fromMailName" placeholder="Your Name or Company" required>
            </div>
            
            <div id="testSection">
                <h2>Send Test Email</h2>
                
                <div class="form-group">
                    <label class="required" for="toEmail">To Email Address</label>
                    <input type="email" id="toEmail" name="toEmail" placeholder="recipient@example.com" required>
                </div>
                
                <div class="form-group">
                    <label class="required" for="subject">Subject</label>
                    <input type="text" id="subject" name="subject" value="Test Email" required>
                </div>
                
                <div class="form-group">
                    <label class="required" for="message">Message</label>
                    <textarea id="message" name="message" rows="5" required>This is a test email sent from the SMTP Email Tester.</textarea>
                </div>
            </div>
            
            <button type="submit">Send Test Email</button>
        </form>
        
        <div class="loading">
            <div class="spinner"></div>
            <p>Sending email...</p>
        </div>
        
        <div class="result" id="resultBox"></div>
    </div>

    <script>
        // SMTP Configuration data for various email providers
        const smtpConfigs = {
            gmail: {
                host: 'smtp.gmail.com',
                port: 465,
                encryption: 'ssl',
                altPort: 587,
                altEncryption: 'tls'
            },
            outlook: {
                host: 'smtp.live.com',
                port: 587,
                encryption: 'tls'
            },
            office365: {
                host: 'smtp.office365.com',
                port: 587,
                encryption: 'tls'
            },
            yahoo: {
                host: 'smtp.mail.yahoo.com',
                port: 465,
                encryption: 'ssl'
            },
            yahooplus: {
                host: 'plus.smtp.mail.yahoo.com',
                port: 465,
                encryption: 'ssl'
            },
            yahoouk: {
                host: 'smtp.mail.yahoo.co.uk',
                port: 465,
                encryption: 'ssl'
            },
            hotmail: {
                host: 'smtp.live.com',
                port: 465,
                encryption: 'ssl',
                altPort: 587,
                altEncryption: 'tls'
            },
            zoho: {
                host: 'smtp.zoho.com',
                port: 465,
                encryption: 'ssl',
                altPort: 587,
                altEncryption: 'tls'
            },
            gmx: {
                host: 'smtp.gmx.com',
                port: 465,
                encryption: 'ssl'
            },
            mailcom: {
                host: 'smtp.mail.com',
                port: 465,
                encryption: 'ssl'
            },
            aol: {
                host: 'smtp.aol.com',
                port: 465,
                encryption: 'ssl',
                altPort: 587,
                altEncryption: 'tls'
            },
            comcast: {
                host: 'smtp.comcast.net',
                port: 587,
                encryption: 'tls'
            },
            verizon: {
                host: 'outgoing.verizon.net',
                port: 465,
                encryption: 'ssl'
            },
            att: {
                host: 'smtp.att.yahoo.com',
                port: 465,
                encryption: 'ssl'
            },
            btinternet: {
                host: 'mail.btinternet.com',
                port: 25,
                encryption: 'none',
                altPort: 465,
                altEncryption: 'ssl'
            },
            orange: {
                host: 'smtp.orange.net',
                port: 25,
                encryption: 'none'
            }
        };

        // Function to update fields based on selected provider
        function updateSmtpFields() {
            const provider = document.getElementById('mailProvider').value;
            const manualConfig = document.getElementById('manualConfig');
            
            // Show or hide manual config based on selection
            if (provider === 'custom') {
                manualConfig.style.display = 'block';
                return;
            } else {
                manualConfig.style.display = 'none';
            }
            
            // Get the config for the selected provider
            const config = smtpConfigs[provider];
            if (!config) return;
            
            // Update the form fields
            document.getElementById('mailHost').value = config.host;
            document.getElementById('mailPort').value = config.port;
            document.getElementById('mailEncryption').value = config.encryption;
            
            // Pre-fill username field with the user's input
            const username = document.getElementById('mailUsername').value;
            if (!username && provider) {
                document.getElementById('fromMailAddress').value = username;
            }
        }
        
        // Toggle manual configuration
        document.getElementById('toggleManual').addEventListener('click', function(e) {
            e.preventDefault();
            const manualConfig = document.getElementById('manualConfig');
            manualConfig.style.display = manualConfig.style.display === 'none' ? 'block' : 'none';
        });
        
        // Update fields when provider changes
        document.getElementById('mailProvider').addEventListener('change', updateSmtpFields);
        
        // Copy username to from address when username changes
        document.getElementById('mailUsername').addEventListener('change', function() {
            const username = this.value;
            const fromAddress = document.getElementById('fromMailAddress');
            if (fromAddress.value === '' && username) {
                fromAddress.value = username;
            }
        });
        
        // Handle form submission
        document.getElementById('emailForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Show loading spinner
            document.querySelector('.loading').style.display = 'block';
            
            // Hide previous result
            const resultBox = document.getElementById('resultBox');
            resultBox.style.display = 'none';
            
            // Collect form data
            const formData = new FormData(this);
            
            // If using a provider preset, add the manual config values
            const provider = document.getElementById('mailProvider').value;
            if (provider !== 'custom') {
                const config = smtpConfigs[provider];
                formData.set('mailHost', config.host);
                formData.set('mailPort', config.port);
                formData.set('mailEncryption', config.encryption);
                formData.set('mailDriver', 'smtp');
            }
            
            // Send AJAX request
            fetch('/send_email', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                // Hide loading spinner
                document.querySelector('.loading').style.display = 'none';
                
                // Display result
                resultBox.style.display = 'block';
                
                if (data.success) {
                    resultBox.className = 'result success';
                    resultBox.innerHTML = `
                        <h3>Success!</h3>
                        <p>${data.message}</p>
                    `;
                } else {
                    resultBox.className = 'result error';
                    resultBox.innerHTML = `
                        <h3>Error</h3>
                        <p>${data.message}</p>
                        ${getErrorHelp(data.message)}
                    `;
                }
            })
            .catch(error => {
                // Hide loading spinner
                document.querySelector('.loading').style.display = 'none';
                
                // Display error
                resultBox.style.display = 'block';
                resultBox.className = 'result error';
                resultBox.innerHTML = `
                    <h3>Error</h3>
                    <p>An unexpected error occurred: ${error.message}</p>
                `;
            });
        });
        
        // Function to provide helpful messages based on common SMTP errors
        function getErrorHelp(errorMessage) {
            let helpText = '';
            
            // Connection errors
            if (errorMessage.includes('Connection refused') || errorMessage.includes('getaddrinfo')) {
                helpText = '<p><strong>Suggestion:</strong> Check if the SMTP host and port are correct. Your ISP might be blocking the port.</p>';
            }
            // Authentication errors
            else if (errorMessage.includes('535') || errorMessage.includes('authentication failed') || errorMessage.includes('auth')) {
                helpText = '<p><strong>Suggestion:</strong> Check your username and password. For Gmail, you need to use an App Password instead of your regular password.</p>';
            }
            // SSL/TLS errors
            else if (errorMessage.includes('SSL') || errorMessage.includes('TLS')) {
                helpText = '<p><strong>Suggestion:</strong> Try a different encryption method or port. Not all servers support SSL/TLS connections.</p>';
            }
            // Timeout errors
            else if (errorMessage.includes('timed out')) {
                helpText = '<p><strong>Suggestion:</strong> The server is not responding. Check your internet connection or try a different port.</p>';
            }
            
            return helpText;
        }
        
        // Initialize the form
        updateSmtpFields();
    </script>
</body>
</html>
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
flask==2.3.2
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY app.py /app/
COPY requirements.txt /app/
COPY templates /app/templates/

RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 8292

# Command to run the app
CMD ["python", "app.py"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3'

services:
  email-tester:
    build: .
    ports:
      - "8292:8292"
    restart: unless-stopped
EOF

echo "Setup complete! You can now build and run the Docker container."
echo "To start the application, run: docker-compose up -d"
