# SMTP Email Tester

An easy-to-use application for testing SMTP email configurations with a clean, user-friendly web interface. This tool helps developers, system administrators, and IT professionals test and troubleshoot email delivery configurations without complex setup.

## Features

- **User-Friendly Interface**: Clean, responsive web interface for configuring and testing SMTP settings
- **Pre-configured Email Providers**: Built-in configurations for popular email services (Gmail, Outlook, Yahoo, etc.)
- **Manual Configuration**: Fully customizable SMTP settings for any email provider
- **Encryption Support**: Test emails with SSL, TLS, or unencrypted connections
- **Detailed Error Reporting**: Clear error messages with troubleshooting suggestions
- **Dockerized Application**: Easy deployment with Docker and Docker Compose

![Image](https://github.com/user-attachments/assets/e6d7a70a-3ca8-4ae0-9f5a-ef0d92040f2b)

## Prerequisites

To run this application, you need to have the following installed on your system:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

1. **Download the setup script**

   Save the `setup.sh` script to your local machine.

2. **Make the script executable**

   ```bash
   chmod +x setup.sh
   ```

3. **Run the setup script**

   ```bash
   ./setup.sh
   ```

   This script will create all necessary files including:
   - Flask application (app.py)
   - HTML template (templates/email_form.html)
   - Dockerfile
   - docker-compose.yml
   - requirements.txt

4. **Build and start the Docker container**

   ```bash
   docker-compose up -d
   ```

5. **Access the application**

   Open your browser and navigate to:
   ```
   http://localhost:8292
   ```

## Manual Setup

If you prefer to set up the application manually instead of using the script, follow these steps:

1. **Create project directory structure**

   ```bash
   mkdir -p smtp-email-tester/templates
   cd smtp-email-tester
   ```

2. **Create app.py file**

   Create a file named `app.py` with the following content:

   ```python
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
   ```

3. **Create HTML template file**

   Create a file named `templates/email_form.html` with the content from the setup script. This is a long HTML file with CSS and JavaScript included - you can find the full content in the setup.sh script.

4. **Create requirements.txt file**

   ```bash
   echo "flask==2.3.2" > requirements.txt
   ```

5. **Create Dockerfile**

   ```bash
   cat > Dockerfile << EOF
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
   ```

6. **Create docker-compose.yml file**

   ```bash
   cat > docker-compose.yml << EOF
   version: '3'

   services:
     email-tester:
       build: .
       ports:
         - "8292:8292"
       restart: unless-stopped
   EOF
   ```

7. **Build and start the container**

   ```bash
   docker-compose up -d
   ```

## Usage Guide

### Basic Usage

1. Open the application in your web browser at `http://localhost:8292`
2. Choose from a pre-configured email provider or select "Custom SMTP Server"
3. Enter your email credentials
4. Fill in the "From" details and recipient information
5. Type a subject and message
6. Click "Send Test Email"

### Provider Selection

The application includes pre-configured settings for the following email providers:

| Provider | Host | Default Port | Encryption |
|----------|------|-------------|------------|
| Gmail | smtp.gmail.com | 465 | SSL |
| Outlook.com | smtp.live.com | 587 | TLS |
| Office365 | smtp.office365.com | 587 | TLS |
| Yahoo Mail | smtp.mail.yahoo.com | 465 | SSL |
| Hotmail | smtp.live.com | 465 | SSL |
| Zoho Mail | smtp.zoho.com | 465 | SSL |
| GMX.com | smtp.gmx.com | 465 | SSL |
| Mail.com | smtp.mail.com | 465 | SSL |
| AOL | smtp.aol.com | 465 | SSL |
| Comcast | smtp.comcast.net | 587 | TLS |
| Verizon | outgoing.verizon.net | 465 | SSL |
| AT&T | smtp.att.yahoo.com | 465 | SSL |
| BT Internet | mail.btinternet.com | 465 | SSL |
| Orange | smtp.orange.net | 25 | None |

### Manual Configuration

For custom SMTP servers, you can manually configure:

- **Mail Driver**: Currently only SMTP is supported
- **Mail Host**: Your SMTP server address (e.g., smtp.example.com)
- **Mail Port**: Common ports include:
  - 25: Standard SMTP (often blocked by ISPs)
  - 465: SSL encryption
  - 587: TLS/StartTLS encryption
  - 2525: Alternative port
- **Mail Encryption**: Choose between SSL, TLS/StartTLS, or None
- **Mail Username**: Typically your full email address
- **Mail Password**: Your email password or app password

### Gmail and Two-Factor Authentication

For Gmail accounts with 2FA enabled, you need to use an App Password:

1. Go to your Google Account settings
2. Navigate to Security > App Passwords
3. Select "Mail" and "Other (Custom name)"
4. Generate an App Password
5. Use this password in the SMTP tester instead of your regular Gmail password

## Troubleshooting

### Common SMTP Errors

- **Connection refused**: Check if the SMTP host and port are correct. Your ISP might be blocking the port.
- **Authentication failed**: Verify your username and password. For services like Gmail, you may need to use an App Password.
- **SSL/TLS errors**: Try a different encryption method or port. Not all servers support SSL/TLS connections.
- **Connection timeout**: The server is not responding. Check your internet connection or try a different port.

### Debugging

The application logs detailed information about each step of the email sending process:

1. To view logs for troubleshooting, run:

   ```bash
   docker-compose logs -f
   ```

## Security Considerations

- This tool is intended for development and testing purposes only
- Never expose this service to the public internet, as it stores email credentials in memory during operation
- For production environments, consider using proper email delivery services
- The app does not store any credentials permanently

## Customization

### Changing the Port

By default, the application runs on port 8292. To change this:

1. Modify the port in `app.py`:

   ```python
   app.run(host='0.0.0.0', port=YOUR_PORT, debug=False)
   ```

2. Update the Dockerfile:

   ```
   EXPOSE YOUR_PORT
   ```

3. Update docker-compose.yml:

   ```yaml
   ports:
     - "YOUR_PORT:YOUR_PORT"
   ```

### Adding More Email Providers

To add additional email providers:

1. Open `templates/email_form.html`
2. Locate the `smtpConfigs` JavaScript object
3. Add your new provider configuration:

   ```javascript
   newProvider: {
       host: 'smtp.newprovider.com',
       port: 465,
       encryption: 'ssl'
   }
   ```

4. Add the provider to the select dropdown:

   ```html
   <option value="newProvider">New Provider Name</option>
   ```

## Running Without Docker

If you prefer not to use Docker, you can run the application directly with Python:

1. Install Python 3.9 or newer
2. Create a virtual environment:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Run the application:

   ```bash
   python app.py
   ```

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues, please submit an issue on the GitHub repository.
