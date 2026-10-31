# 📧 Email Invitation System Setup Guide

The email invitation system has been successfully implemented! Follow these steps to set it up.

## ✅ What Was Implemented

1. **Firebase Cloud Function** (`sendEventInvitationEmails`)
   - Professional HTML email template with event details
   - Batch sending to handle rate limits
   - Gmail SMTP integration via Nodemailer
   - Comprehensive error handling

2. **Swift UI Integration**
   - CSV file parsing (Excel files can be exported as CSV)
   - Email validation and duplicate removal
   - Real-time progress tracking
   - Cloud Function integration with error handling

3. **Email Template Features**
   - Event name, date, time
   - Venue and location
   - Ticket price (or "Starting from" for multiple ticket types)
   - Host name and username
   - Universal link button (`https://kiccbacc.com/event/{eventID}`)
   - Professional, mobile-responsive design

## 🚀 Setup Instructions

### Step 1: Install Dependencies

```bash
cd functions
npm install
```

This will install `nodemailer@^6.9.8` that was added to `package.json`.

### Step 2: Set Up Gmail App Password

1. **Go to your Google Account**: https://myaccount.google.com/
2. **Enable 2-Factor Authentication** (if not already enabled)
3. **Generate App Password**:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Enter "KiccBacc Events"
   - Click "Generate"
   - Copy the 16-character password (it will look like: `abcd efgh ijkl mnop`)

### Step 3: Configure Firebase Environment Variables

Set the Gmail credentials as environment variables in Firebase:

```bash
# Set Gmail user (your Gmail address)
firebase functions:config:set gmail.user="your-email@gmail.com"

# Set Gmail app password (the 16-character password from Step 2)
firebase functions:config:set gmail.password="abcd efgh ijkl mnop"
```

**Note**: Remove spaces from the app password when setting it.

### Step 4: Update Cloud Function to Use Config

The Cloud Function reads these values from `process.env.GMAIL_USER` and `process.env.GMAIL_APP_PASSWORD`. 

For local testing, create a `.env` file in the `functions` directory:

```bash
# functions/.env
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=abcdefghijklmnop
```

⚠️ **Important**: Add `.env` to your `.gitignore` to avoid committing credentials!

### Step 5: Deploy the Cloud Function

```bash
firebase deploy --only functions:sendEventInvitationEmails
```

### Step 6: Test the System

1. Open the KiccBacc app
2. Navigate to an event you host
3. Tap on **Event Properties**
4. Tap on **Import List**
5. Upload a CSV file with emails (one per row, first column)
6. Review the extracted emails
7. Tap **Send Invitations**

## 📝 CSV File Format

Your CSV file should look like this:

```csv
email
john.doe@example.com
jane.smith@example.com
mike.wilson@example.com
```

Or without headers:

```csv
john.doe@example.com
jane.smith@example.com
mike.wilson@example.com
```

**Excel Users**: Save your Excel file as "CSV UTF-8 (Comma delimited)" format.

## 🔒 Security Notes

- The Gmail App Password is **NOT** your Gmail password
- App passwords are revocable at any time
- Never commit credentials to version control
- The Cloud Function only accepts authenticated requests from your app

## 📊 Rate Limits

- **Gmail Free**: 500 emails per day
- The function sends emails in batches of 10 with 2-second delays to respect rate limits
- Failed emails are tracked and reported back to the app

## 🎨 Email Template Preview

The email includes:
- KiccBacc branding header
- Event banner image
- Event name and details
- Date, time, location
- Ticket pricing
- Host information (name + username)
- "View Event Details" button with universal link
- Professional footer with social links

## 🐛 Troubleshooting

### Error: "Gmail credentials not configured"
- Make sure you ran the `firebase functions:config:set` commands
- For local testing, ensure `.env` file exists in `functions/` directory

### Error: "Invalid login"
- Double-check your Gmail address
- Verify the App Password is correct (16 characters, no spaces)
- Ensure 2FA is enabled on your Google account

### Emails not sending
- Check Firebase Functions logs: `firebase functions:log`
- Verify you haven't exceeded Gmail's 500 emails/day limit
- Check spam folder for test emails

### CSV parsing issues
- Ensure emails are in the first column
- Use UTF-8 encoding
- Remove any special characters or formatting

## 📞 Support

For issues or questions, check the Firebase Functions logs:

```bash
firebase functions:log --only sendEventInvitationEmails
```

## 🎉 You're All Set!

Your event invitation system is ready to use. Host users can now easily import email lists and send professional invitations with event details and universal links!

---

**Note**: Remember to monitor your email sending usage to stay within Gmail's daily limits. For higher volume needs, consider upgrading to SendGrid or Brevo.


