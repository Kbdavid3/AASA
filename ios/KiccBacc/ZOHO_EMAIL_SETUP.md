# 📧 Zoho Mail Setup for KiccBacc Events (FREE!)

Get `events@kiccbacc.com` email **completely FREE** with Zoho Mail's Forever Free plan!

---

## ✨ What You Get (FREE)

- ✅ Custom domain email: `events@kiccbacc.com`
- ✅ 5 email users
- ✅ 5GB storage per user
- ✅ Mobile & Desktop apps
- ✅ No ads
- ✅ Professional email
- ✅ Forever FREE (no credit card required)

---

## 🚀 Setup Guide (15 minutes)

### Step 1: Sign Up for Zoho Mail

1. Go to: **https://www.zoho.com/mail/**
2. Click **"Sign Up Now"** button
3. Select **"Forever Free"** plan
4. Choose **"Add your existing domain"**
5. Enter domain: **`kiccbacc.com`**
6. Create your Zoho account

---

### Step 2: Verify Domain Ownership

Zoho will provide a verification code. Add it to your domain's DNS:

#### **For Namecheap:**
```
1. Login to Namecheap
2. Go to Domain List → Manage → Advanced DNS
3. Add TXT Record:
   - Type: TXT Record
   - Host: @
   - Value: zoho-verification=xxxxxx.zmverify.zoho.com
   - TTL: Automatic
```

#### **For GoDaddy:**
```
1. Login to GoDaddy
2. Go to My Products → DNS
3. Add TXT Record:
   - Type: TXT
   - Name: @
   - Value: zoho-verification=xxxxxx.zmverify.zoho.com
   - TTL: 1 Hour
```

#### **For Cloudflare:**
```
1. Login to Cloudflare
2. Select your domain → DNS → Records
3. Add TXT Record:
   - Type: TXT
   - Name: @
   - Content: zoho-verification=xxxxxx.zmverify.zoho.com
   - TTL: Auto
```

**Wait 5-10 minutes** for DNS propagation, then click "Verify" in Zoho.

---

### Step 3: Configure MX Records

Add these MX records to your domain:

#### **MX Records to Add:**
```
Priority 10:  mx.zoho.com
Priority 20:  mx2.zoho.com  
Priority 50:  mx3.zoho.com
```

#### **For Namecheap:**
```
Advanced DNS → Add New Record → MX Record:

Record 1:
- Type: MX Record
- Host: @
- Value: mx.zoho.com
- Priority: 10

Record 2:
- Type: MX Record
- Host: @
- Value: mx2.zoho.com
- Priority: 20

Record 3:
- Type: MX Record
- Host: @
- Value: mx3.zoho.com
- Priority: 50
```

#### **For GoDaddy:**
```
DNS Settings → MX → Add:

Record 1:
- Priority: 10
- Points to: mx.zoho.com

Record 2:
- Priority: 20
- Points to: mx2.zoho.com

Record 3:
- Priority: 50
- Points to: mx3.zoho.com
```

⚠️ **Important**: Remove any existing MX records (like default email forwarding)

---

### Step 4: Configure SPF Record (Recommended)

Add SPF record for better email deliverability:

```
Type: TXT Record
Host: @
Value: v=spf1 include:zoho.com ~all
TTL: Automatic
```

---

### Step 5: Create Email Account

1. Login to Zoho Mail admin panel
2. Go to **"Users"** → **"Add User"**
3. Create user:
   ```
   Email Address: events
   Full email: events@kiccbacc.com
   First Name: KiccBacc
   Last Name: Events
   Password: [Create strong password]
   ```
4. Click **"Add"**

---

### Step 6: Test Email

1. Login to: **https://mail.zoho.com/**
2. Username: `events@kiccbacc.com`
3. Password: [your password]
4. Send a test email to yourself
5. Verify it arrives successfully

---

### Step 7: Configure Firebase

```bash
# Navigate to your project
cd "/Users/sid/Downloads/KiccBaccBackup-main copy"

# Set Zoho email credentials
firebase functions:config:set gmail.user="events@kiccbacc.com"
firebase functions:config:set gmail.password="your-zoho-password"

# Set Zoho SMTP settings
firebase functions:config:set smtp.host="smtp.zoho.com"
firebase functions:config:set smtp.port="465"

# Verify configuration
firebase functions:config:get
```

---

### Step 8: Deploy Function

```bash
firebase deploy --only functions:sendEventInvitationEmails
```

---

### Step 9: Test in App

1. Open KiccBacc app
2. Go to any event → Event Properties → Import List
3. Upload CSV with your email
4. Send test invitation
5. Check if email arrives from `events@kiccbacc.com` ✅

---

## 🔧 Zoho SMTP Settings

Use these if needed:

```
SMTP Host: smtp.zoho.com
SMTP Port: 465 (SSL) or 587 (TLS)
SMTP Security: SSL/TLS
Username: events@kiccbacc.com
Password: [your Zoho password]
```

---

## 📱 Zoho Mail Apps

Access your email anywhere:

- **Web**: https://mail.zoho.com/
- **iOS App**: Download "Zoho Mail" from App Store
- **Android App**: Download "Zoho Mail" from Play Store
- **Desktop**: Use any email client (Apple Mail, Outlook, Thunderbird)

---

## 🎨 Email Configuration for Apple Mail / Outlook

If you want to use Apple Mail or Outlook:

### **Incoming (IMAP):**
```
Server: imap.zoho.com
Port: 993
Security: SSL
Username: events@kiccbacc.com
Password: [your password]
```

### **Outgoing (SMTP):**
```
Server: smtp.zoho.com
Port: 465
Security: SSL
Username: events@kiccbacc.com
Password: [your password]
```

---

## 🐛 Troubleshooting

### "Domain verification failed"
- ✅ Check TXT record is added correctly
- ✅ Wait 10-15 minutes for DNS propagation
- ✅ Use DNS checker: https://mxtoolbox.com/SuperTool.aspx

### "Cannot receive emails"
- ✅ Verify MX records are added correctly
- ✅ Remove any old MX records
- ✅ Check MX priority is correct (10, 20, 50)
- ✅ Wait up to 24 hours for full DNS propagation

### "SMTP authentication failed"
- ✅ Check username is full email: `events@kiccbacc.com`
- ✅ Verify password is correct
- ✅ Try port 587 instead of 465
- ✅ Enable "Less Secure Apps" in Zoho settings (if needed)

### Emails going to spam
- ✅ Add SPF record (see Step 4)
- ✅ Add DKIM record (in Zoho admin → Email Configuration)
- ✅ Warm up email (start with small batches)
- ✅ Ask recipients to whitelist

---

## 📊 Zoho Free Plan Limits

- **Users**: 5 mailboxes
- **Storage**: 5GB per user
- **Attachments**: 25MB
- **Email Aliases**: 10 per user
- **Sending Limit**: Check Zoho's current limits
- **Cost**: **$0/month FOREVER** 🎉

---

## 🚀 Upgrade Options (If Needed)

If you need more:

| Plan | Cost | Storage | Users |
|------|------|---------|-------|
| **Free** | **$0** | 5GB | 5 |
| Mail Lite | $1/user/mo | 10GB | Unlimited |
| Mail Premium | $4/user/mo | 50GB | Unlimited |

---

## ✅ Setup Checklist

- [ ] Sign up for Zoho Mail Free
- [ ] Add domain `kiccbacc.com`
- [ ] Add TXT verification record
- [ ] Verify domain ownership
- [ ] Add MX records (3 records)
- [ ] Add SPF record
- [ ] Create email: `events@kiccbacc.com`
- [ ] Test login at mail.zoho.com
- [ ] Send test email to yourself
- [ ] Configure Firebase with Zoho credentials
- [ ] Deploy Cloud Function
- [ ] Test from KiccBacc app
- [ ] Verify email arrives from `events@kiccbacc.com`

---

## 🎉 You're Done!

You now have:
- ✅ Professional email: `events@kiccbacc.com`
- ✅ 100% FREE forever
- ✅ Custom domain branding
- ✅ Integrated with KiccBacc app
- ✅ Ready to send invitations!

---

## 📞 Support

**Zoho Support**: https://help.zoho.com/portal/en/home  
**DNS Propagation Check**: https://www.whatsmydns.net/  
**MX Record Check**: https://mxtoolbox.com/

**Firebase Logs**:
```bash
firebase functions:log --only sendEventInvitationEmails
```

---

**Pro Tip**: Bookmark `mail.zoho.com` and download the mobile app to manage your KiccBacc emails on the go! 📱


