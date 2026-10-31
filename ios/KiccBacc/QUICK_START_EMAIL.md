# 🚀 Quick Start Guide - Email Invitations

## ⚡ 3-Minute Setup

### 1️⃣ Get Gmail App Password (2 min)
```
1. Visit: https://myaccount.google.com/apppasswords
2. Create password for "KiccBacc Events"
3. Copy the 16-character code
```

### 2️⃣ Configure Firebase (30 sec)
```bash
firebase functions:config:set gmail.user="your-email@gmail.com"
firebase functions:config:set gmail.password="abcdefghijklmnop"
```

### 3️⃣ Deploy (30 sec)
```bash
cd functions
npm install
cd ..
firebase deploy --only functions:sendEventInvitationEmails
```

### 4️⃣ Test (1 min)
```
1. Open KiccBacc app
2. Go to any event → Event Properties
3. Tap "Import List"
4. Upload CSV with test emails
5. Send invitations! 🎉
```

---

## 📄 CSV Format

```csv
email
john@example.com
jane@example.com
```

**Excel Users**: Save As → CSV UTF-8

---

## 📧 What Recipients Get

Professional email with:
- ✅ Event name, date, time
- ✅ Location with map
- ✅ Ticket price
- ✅ Host info
- ✅ Universal link button
- ✅ Beautiful design

---

## 📊 Limits

- **Free Gmail**: 500 emails/day
- **Batch size**: 10 emails at a time
- **Rate limiting**: Built-in 2s delays

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Credentials not configured" | Run Step 2 above |
| "Invalid login" | Check app password (not regular password) |
| "CSV failed" | Emails must be in first column |
| Emails in spam | Ask recipients to whitelist |

**View logs**: `firebase functions:log`

---

## ✅ Done!

You're all set. Import email lists and send professional event invitations! 🎊

For detailed docs, see: `EMAIL_INVITATION_SETUP.md`


