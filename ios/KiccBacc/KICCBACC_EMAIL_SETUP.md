# 📧 Using KiccBacc Email for Invitations

This guide shows you how to use a **KiccBacc-branded email** (like `events@kiccbacc.com`) for sending event invitations instead of a personal Gmail.

---

## 🎯 **Option 1: Google Workspace Email (Recommended)**

If you have **`events@kiccbacc.com`** through **Google Workspace**:

### **Setup Steps:**

#### 1. Generate App Password
```
1. Login to events@kiccbacc.com
2. Visit: https://myaccount.google.com/apppasswords
3. Select "Mail" and "Other (Custom name)"
4. Enter: "KiccBacc Event Invitations"
5. Click Generate
6. Copy the 16-character password
```

#### 2. Configure Firebase
```bash
# Set your KiccBacc email
firebase functions:config:set gmail.user="events@kiccbacc.com"

# Set the app password
firebase functions:config:set gmail.password="abcdefghijklmnop"
```

#### 3. Deploy
```bash
firebase deploy --only functions:sendEventInvitationEmails
```

#### 4. Test
Send a test invitation from the app!

**Result**: Emails will show as:
```
From: "KiccBacc Events" <events@kiccbacc.com>
```

### **Benefits:**
✅ Professional appearance  
✅ Brand recognition  
✅ Better email deliverability  
✅ 2,000 emails/day (Google Workspace)  
✅ Easy setup (same as Gmail)  

**Cost**: $6/month per user (Google Workspace)

---

## 🎯 **Option 2: Custom Email Provider (Namecheap, GoDaddy, etc.)**

If you have **`events@kiccbacc.com`** with another provider:

### **Setup Steps:**

#### 1. Get SMTP Credentials
From your email provider, get:
- SMTP Host (e.g., `smtp.privateemail.com`)
- SMTP Port (usually `465` or `587`)
- Email address: `events@kiccbacc.com`
- Email password

#### 2. Configure Firebase
```bash
# Set your email credentials
firebase functions:config:set gmail.user="events@kiccbacc.com"
firebase functions:config:set gmail.password="your-email-password"

# Set SMTP settings (for custom providers)
firebase functions:config:set smtp.host="smtp.privateemail.com"
firebase functions:config:set smtp.port="465"
```

#### 3. Deploy
```bash
firebase deploy --only functions:sendEventInvitationEmails
```

**Result**: Emails will send through your custom SMTP server!

### **Common SMTP Settings:**

| Provider | SMTP Host | Port | Secure |
|----------|-----------|------|--------|
| Namecheap | `mail.privateemail.com` | 465 | Yes |
| GoDaddy | `smtpout.secureserver.net` | 465 | Yes |
| Bluehost | `mail.yourdomain.com` | 465 | Yes |
| HostGator | `mail.yourdomain.com` | 465 | Yes |
| Zoho Mail | `smtp.zoho.com` | 465 | Yes |

**Note**: Replace `yourdomain.com` with `kiccbacc.com`

---

## 🎯 **Option 3: Don't Have KiccBacc Email? Set One Up!**

### **Quick Options:**

#### **A. Google Workspace** (Recommended)
- **Cost**: $6/month
- **Email**: events@kiccbacc.com
- **Limit**: 2,000 emails/day
- **Setup**: https://workspace.google.com/

**Steps:**
1. Sign up for Google Workspace
2. Add domain: `kiccbacc.com`
3. Verify domain ownership
4. Create email: `events@kiccbacc.com`
5. Follow "Option 1" setup above

#### **B. Namecheap Private Email**
- **Cost**: $0.99/month
- **Email**: events@kiccbacc.com
- **Limit**: Check provider limits
- **Setup**: https://www.namecheap.com/hosting/email/

**Steps:**
1. Purchase email hosting for `kiccbacc.com`
2. Create email: `events@kiccbacc.com`
3. Get SMTP credentials
4. Follow "Option 2" setup above

#### **C. Zoho Mail**
- **Cost**: FREE (up to 5 users) or $1/month
- **Email**: events@kiccbacc.com
- **Limit**: Check provider limits
- **Setup**: https://www.zoho.com/mail/

---

## 📊 **Email Sending Limits Comparison**

| Provider | Free Limit | Paid Limit | Cost |
|----------|-----------|------------|------|
| Personal Gmail | 500/day | 2,000/day | $6/mo (Workspace) |
| Google Workspace | N/A | 2,000/day | $6/mo |
| Custom SMTP | Varies | Varies | $1-5/mo |
| SendGrid | 100/day | 50k/month | $20/mo |

---

## ✅ **Recommended Setup**

For **KiccBacc**, I recommend:

### **Best Option: Google Workspace**
```
Email: events@kiccbacc.com
Provider: Google Workspace
Cost: $6/month
Limit: 2,000 emails/day
```

**Why?**
- ✅ Professional appearance
- ✅ Reliable delivery (99.9% uptime)
- ✅ Easy setup (just like Gmail)
- ✅ High sending limit
- ✅ Spam protection
- ✅ Good reputation

---

## 🔧 **Current Configuration**

Check your current email settings:
```bash
firebase functions:config:get
```

Update email settings:
```bash
# For Google Workspace or Gmail
firebase functions:config:set gmail.user="events@kiccbacc.com"
firebase functions:config:set gmail.password="your-app-password"

# For custom SMTP (optional)
firebase functions:config:set smtp.host="smtp.provider.com"
firebase functions:config:set smtp.port="465"
```

Deploy changes:
```bash
firebase deploy --only functions:sendEventInvitationEmails
```

---

## 🎨 **Email Branding**

Emails will show as:
```
From: "KiccBacc Events" <events@kiccbacc.com>
Subject: You're Invited: [Event Name]
```

The sender name **"KiccBacc Events"** is already configured in the code. You can change it if needed.

---

## 🐛 **Troubleshooting**

### "Authentication failed"
- ✅ Check email address is correct
- ✅ Verify password/app password
- ✅ For Gmail/Workspace: Use app password, not regular password
- ✅ For custom SMTP: Use email password

### "Connection refused"
- ✅ Check SMTP host is correct
- ✅ Verify SMTP port (465 or 587)
- ✅ Ensure firewall allows outbound SMTP

### Emails going to spam
- ✅ Set up SPF record for your domain
- ✅ Set up DKIM for your domain
- ✅ Start with small batches (warm up)
- ✅ Ask recipients to whitelist events@kiccbacc.com

### View logs:
```bash
firebase functions:log --only sendEventInvitationEmails
```

---

## 📧 **Setting Up Domain Records (Advanced)**

To improve email deliverability, add these DNS records:

### **SPF Record**
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.google.com ~all
```

### **DKIM Record**
Get from Google Workspace Admin → Apps → Gmail → Authenticate email

### **DMARC Record**
```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=none; rua=mailto:events@kiccbacc.com
```

**Note**: These are optional but recommended for best deliverability.

---

## ✨ **Quick Start Checklist**

- [ ] Have `events@kiccbacc.com` email (or set it up)
- [ ] Get email credentials (app password or SMTP)
- [ ] Configure Firebase with credentials
- [ ] Deploy Cloud Function
- [ ] Test with your own email
- [ ] Send test invitation from app
- [ ] Check spam folder
- [ ] Verify universal link works

---

## 🎉 **You're Ready!**

Once configured, all event invitations will be sent from **`events@kiccbacc.com`** with professional branding!

**Need help?** Check the logs:
```bash
firebase functions:log --only sendEventInvitationEmails
```

---

**Recommended Next Steps:**
1. Set up `events@kiccbacc.com` with Google Workspace
2. Configure Firebase environment variables
3. Deploy the function
4. Test with a small batch
5. Start sending invitations! 🚀


