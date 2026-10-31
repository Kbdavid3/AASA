# 📧 New Gmail Account Setup for KiccBacc Events (100% FREE!)

Set up a dedicated Gmail account for sending event invitations - **completely free!**

---

## ✨ What You Get (FREE)

- ✅ Dedicated email: `kiccbaccevents@gmail.com`
- ✅ 500 emails per day
- ✅ 15GB storage
- ✅ Professional appearance
- ✅ Google's reliable infrastructure
- ✅ Mobile & Desktop apps
- ✅ Forever FREE

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Create Gmail Account

1. **Go to Gmail**:
   ```
   Visit: https://accounts.google.com/signup
   ```

2. **Choose Username**:
   Pick one of these (or similar):
   ```
   ✅ kiccbaccevents@gmail.com (Recommended)
   ✅ events.kiccbacc@gmail.com
   ✅ kiccbacc.events@gmail.com
   ✅ hello.kiccbacc@gmail.com
   ✅ invites.kiccbacc@gmail.com
   ```

3. **Fill Details**:
   ```
   First Name: KiccBacc
   Last Name: Events
   Username: kiccbaccevents
   Password: [Create strong password - save it!]
   ```

4. **Complete Setup**:
   - Skip phone number (or add if required)
   - Skip recovery email (or add if required)
   - Accept Terms of Service
   - Complete CAPTCHA

---

### Step 2: Enable 2-Factor Authentication

**Required for App Passwords!**

1. Login to the new Gmail account
2. Go to: **https://myaccount.google.com/security**
3. Under "Signing in to Google", click **"2-Step Verification"**
4. Click **"Get Started"**
5. Follow the setup wizard:
   - Add phone number
   - Verify with code
   - Turn on 2-Step Verification

---

### Step 3: Generate App Password

**This is what Firebase will use to send emails:**

1. Go to: **https://myaccount.google.com/apppasswords**
2. Click **"Select app"** → Choose **"Mail"**
3. Click **"Select device"** → Choose **"Other (Custom name)"**
4. Enter name: **"KiccBacc Event Invitations"**
5. Click **"Generate"**
6. **COPY THE 16-CHARACTER PASSWORD** (looks like: `abcd efgh ijkl mnop`)
7. Save it somewhere safe!

---

### Step 4: Configure Firebase

```bash
# Navigate to your project
cd "/Users/sid/Downloads/KiccBaccBackup-main copy"

# Set Gmail credentials
firebase functions:config:set gmail.user="kiccbaccevents@gmail.com"

# Set app password (remove spaces)
firebase functions:config:set gmail.password="abcdefghijklmnop"

# Verify configuration
firebase functions:config:get
```

**Note**: When setting the password, remove all spaces from the 16-character code.

---

### Step 5: Deploy Function

```bash
firebase deploy --only functions:sendEventInvitationEmails
```

Wait for deployment to complete (~1-2 minutes).

---

### Step 6: Test

1. Open **KiccBacc app**
2. Navigate to any event you host
3. Tap **Event Properties** → **Import List**
4. Upload CSV with your personal email
5. Tap **Send Invitations**
6. Check your inbox for email from `kiccbaccevents@gmail.com` ✅

---

## 📧 Email Appearance

Recipients will see:
```
From: "KiccBacc Events" <kiccbaccevents@gmail.com>
Subject: You're Invited: [Event Name]
```

Professional and recognizable! 🎉

---

## 🔧 Gmail SMTP Settings (For Reference)

The Cloud Function uses:
```
Service: gmail
Username: kiccbaccevents@gmail.com
Password: [16-char app password]
Port: 465 (SSL)
```

---

## 📊 Gmail Sending Limits

| Account Type | Daily Limit | Cost |
|--------------|-------------|------|
| **Free Gmail** | **500/day** | **$0** ✅ |
| Google Workspace | 2,000/day | $6/month |

**500 emails/day** is usually enough for most events!

---

## 💡 Pro Tips

### 1. Set Up Email Signature
1. Login to Gmail: https://mail.google.com/
2. Settings → See all settings → Signature
3. Create signature:
   ```
   --
   KiccBacc Events
   Create Memories, Share Moments
   https://kiccbacc.com
   ```

### 2. Set Up Mobile App
- Download **Gmail app** on your phone
- Add the `kiccbaccevents@gmail.com` account
- Monitor sent emails and responses

### 3. Create Filters
Set up filters to organize:
- Automated emails
- Bounce notifications
- Out-of-office replies

### 4. Enable Vacation Responder (Optional)
For times when no one monitors the account:
```
Settings → Vacation responder
Message: "Thank you for your email. For event inquiries,
please contact us through the KiccBacc app."
```

---

## 🎨 Customize Display Name (Optional)

Make it more professional:

1. Go to Gmail Settings → Accounts and Import
2. Under "Send mail as", click **"edit info"**
3. Change name to one of:
   ```
   ✅ KiccBacc Events
   ✅ KiccBacc Team
   ✅ KiccBacc Invitations
   ```

Recipients will see: `"KiccBacc Events" <kiccbaccevents@gmail.com>`

---

## 🐛 Troubleshooting

### "App Passwords option not showing"
**Solution**: 
- Ensure 2-Step Verification is enabled
- Wait 5-10 minutes after enabling 2FA
- Try in incognito/private browser window

### "Invalid credentials" error
**Solution**:
- Use the app password, NOT your regular Gmail password
- Remove spaces from the 16-character code
- Regenerate app password if needed

### "Daily sending limit exceeded"
**Solution**:
- You've sent 500 emails today
- Wait until tomorrow (resets at midnight PST)
- Consider using multiple Gmail accounts
- Or upgrade to Google Workspace

### Emails going to spam
**Solution**:
- Send smaller batches first (start with 10-20)
- Ask recipients to add to contacts
- Include unsubscribe option
- Warm up the account gradually

---

## 🔐 Security Best Practices

✅ **Never share** the app password  
✅ **Store it securely** (password manager)  
✅ **Regenerate** if compromised  
✅ **Monitor** sent emails regularly  
✅ **Enable alerts** for unusual activity  

---

## 📈 Scaling Up

If you need more than 500 emails/day:

### Option 1: Multiple Gmail Accounts
```
Create:
- kiccbaccevents1@gmail.com (500/day)
- kiccbaccevents2@gmail.com (500/day)
- kiccbaccevents3@gmail.com (500/day)

Total: 1,500 emails/day for FREE!
```

Rotate between accounts in your sending logic.

### Option 2: Upgrade to Google Workspace
```
Cost: $6/month per user
Limit: 2,000 emails/day
Email: events@kiccbacc.com (custom domain)
```

### Option 3: Use Zoho Mail
```
Cost: FREE
Limit: Varies
Email: events@kiccbacc.com (custom domain)
```

See `ZOHO_EMAIL_SETUP.md` for details.

---

## ✅ Setup Checklist

- [ ] Create Gmail account (`kiccbaccevents@gmail.com`)
- [ ] Set strong password
- [ ] Enable 2-Factor Authentication
- [ ] Generate App Password
- [ ] Copy 16-character code
- [ ] Configure Firebase with credentials
- [ ] Deploy Cloud Function
- [ ] Test email from app
- [ ] Verify email arrives
- [ ] Check spam folder
- [ ] Set up mobile app (optional)
- [ ] Create email signature (optional)

---

## 🎉 You're Ready!

You now have:
- ✅ Dedicated email for KiccBacc events
- ✅ 500 emails/day sending capacity
- ✅ Professional appearance
- ✅ 100% FREE forever
- ✅ Ready to send invitations!

---

## 📞 Quick Commands

**View configuration**:
```bash
firebase functions:config:get
```

**View logs**:
```bash
firebase functions:log --only sendEventInvitationEmails
```

**Redeploy function**:
```bash
firebase deploy --only functions:sendEventInvitationEmails
```

**Test locally** (optional):
```bash
cd functions
firebase functions:shell
```

---

## 📧 Example Email Names

If `kiccbaccevents@gmail.com` is taken, try:

- `kiccbacc.events@gmail.com`
- `events.kiccbacc@gmail.com`
- `kiccbaccapp@gmail.com`
- `hello.kiccbacc@gmail.com`
- `invites.kiccbacc@gmail.com`
- `notifications.kiccbacc@gmail.com`
- `team.kiccbacc@gmail.com`

Pick something memorable and professional! 🎯

---

**Ready to send your first invitation?** 🚀

Test with a small batch first to ensure everything works perfectly!


