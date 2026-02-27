import os
import smtplib
from email.message import EmailMessage

SMTP_HOST = os.environ.get("SMTP_HOST")
SMTP_PORT = int(os.environ.get("SMTP_PORT", "0")) if os.environ.get("SMTP_PORT") else None
SMTP_USER = os.environ.get("SMTP_USER")
SMTP_PASS = os.environ.get("SMTP_PASS")
FROM_EMAIL = os.environ.get("FROM_EMAIL", SMTP_USER)


def send_email(to_email: str, subject: str, body: str):
    if not SMTP_HOST or not SMTP_PORT:
        raise RuntimeError("SMTP configuration not set (SMTP_HOST / SMTP_PORT)")

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email
    msg.set_content(body)

    # Support SSL (465) and STARTTLS (other ports)
    if SMTP_PORT == 465:
        server = smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT)
    else:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls()

    try:
        if SMTP_USER and SMTP_PASS:
            server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)
    finally:
        server.quit()


def send_otp_email(to_email: str, otp: str):
    subject = "Your LastBench password reset OTP"
    body = f"Your OTP for LastBench password reset is: {otp}\nThis code is valid for 10 minutes. If you did not request this, ignore this email."

    # For development, optionally print OTP to console
    if os.environ.get("DEV_SHOW_OTP", "false").lower() == "true":
        print(f"[email] DEV_SHOW_OTP enabled — OTP for {to_email}: {otp}")

    try:
        send_email(to_email, subject, body)
        print(f"[email] OTP email sent to {to_email}")
    except Exception as e:
        print(f"[email] Failed to send OTP email to {to_email}: {e}")
        raise
