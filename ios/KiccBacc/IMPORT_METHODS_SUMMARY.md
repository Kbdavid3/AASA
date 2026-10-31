# 📊 Email Import Methods - Complete Guide

## 🎉 **Three Ways to Import Emails!**

Your KiccBacc app now supports **3 flexible import methods**:

---

## ✨ **Method 1: Google Sheets** (⭐ RECOMMENDED!)

### **Why This is Best:**
✅ **No file upload** - Just paste a link  
✅ **Real-time** - Sheet updates automatically  
✅ **Team collaboration** - Multiple people can add emails  
✅ **Always accessible** - Works from any device  
✅ **Easy to update** - Change emails anytime  

### **Quick Start:**
```
1. Create Google Sheet: https://sheets.google.com/
2. Add emails in Column A
3. Click Share → "Anyone with link can view"
4. Copy the share link
5. In app: Event Properties → Import List → Google Sheets tab
6. Paste link → Import!
```

### **Example:**
```
Google Sheet:
A1: email
A2: john@example.com
A3: jane@example.com
A4: mike@example.com

Share link: https://docs.google.com/spreadsheets/d/ABC123...
```

---

## 📁 **Method 2: Excel Files** (.xlsx)

### **Best For:**
- Existing contact lists in Excel
- Offline data management
- Local file storage

### **Quick Start:**
```
1. Open Excel file
2. Put emails in Column A
3. Save file
4. In app: Event Properties → Import List → Upload File tab
5. Select your Excel file
6. Done!
```

### **Pro Tip:**
For best results, export Excel as CSV:
```
File → Save As → CSV UTF-8 (Comma delimited)
```

---

## 📄 **Method 3: CSV Files** (.csv)

### **Best For:**
- Simple email lists
- Quick imports
- Maximum compatibility

### **Quick Start:**
```
1. Create text file with emails
2. Save as .csv
3. In app: Event Properties → Import List → Upload File tab
4. Upload CSV
```

### **Example CSV:**
```
email
john@example.com
jane@example.com
mike@example.com
```

---

## 📊 **Comparison Table**

| Feature | Google Sheets | Excel (.xlsx) | CSV |
|---------|---------------|---------------|-----|
| **Ease** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **No Upload** | ✅ | ❌ | ❌ |
| **Collaborate** | ✅ | Partial | ❌ |
| **Offline** | ❌ | ✅ | ✅ |
| **Updates** | Real-time | Manual | Manual |
| **Setup Time** | 2 min | 1 min | 1 min |

---

## 🎯 **How It Works in the App**

### **User Interface:**
```
Event Properties → Import List

[Tab: Upload File]  [Tab: Google Sheets]

Upload File Tab:
- Choose CSV or Excel file
- App extracts emails automatically
- Preview before sending

Google Sheets Tab:
- Paste Google Sheets link
- App fetches emails directly
- Preview before sending
```

### **What Happens:**
1. ✅ App validates all email formats
2. ✅ Removes duplicate emails
3. ✅ Skips header rows automatically
4. ✅ Shows preview of extracted emails
5. ✅ You review and send!

---

## 💡 **Best Practices**

### **For Google Sheets:**
```
✅ Use one master sheet for all events
✅ Share with your team
✅ Update anytime - no re-import needed
✅ Use Google Sheets formulas to validate emails
✅ Filter large lists easily
```

### **For Excel:**
```
✅ Keep emails in Column A only
✅ Save as CSV for best results
✅ Remove all formatting
✅ Use UTF-8 encoding
```

### **For CSV:**
```
✅ One email per line
✅ Plain text only
✅ UTF-8 encoding
✅ Simple is better
```

---

## 🔧 **Technical Details**

### **What's Supported:**
- ✅ CSV files (.csv)
- ✅ Excel files (.xlsx, .xls)
- ✅ Google Sheets (shareable links)
- ✅ Up to 500 emails per batch
- ✅ Automatic validation
- ✅ Duplicate removal
- ✅ Header detection

### **File Requirements:**
- **Column**: Emails must be in first column (Column A)
- **Format**: Valid email format (name@domain.com)
- **Size**: Max 10MB file size
- **Encoding**: UTF-8 preferred

---

## 🎨 **Example Workflows**

### **Workflow 1: Team Event**
```
1. Create Google Sheet
2. Share with co-hosts
3. Everyone adds their contacts
4. Paste link in app
5. Send invitations!
```

### **Workflow 2: Corporate Event**
```
1. Export contacts from Outlook/Gmail to CSV
2. Upload CSV in app
3. Preview emails
4. Send invitations!
```

### **Workflow 3: Quick Test**
```
1. Create simple CSV:
   email
   your-email@gmail.com
2. Upload
3. Test!
```

---

## 🐛 **Troubleshooting**

### **Google Sheets:**
- **"Invalid URL"**: Make sure link contains `docs.google.com/spreadsheets`
- **"Permission denied"**: Set sharing to "Anyone with link can view"
- **"No emails found"**: Put emails in Column A (first column)

### **Excel:**
- **"Can't extract"**: Try saving as CSV instead
- **"Unsupported"**: Use .xlsx or .csv format
- **"No emails"**: Ensure Column A has emails

### **CSV:**
- **"Invalid format"**: Use UTF-8 encoding
- **"No emails"**: Check email format (must have @)
- **"Parse error"**: Remove special characters

---

## ✅ **You're All Set!**

You now have **3 powerful ways** to import emails:

1. **Google Sheets** - For teams and flexibility
2. **Excel** - For existing data
3. **CSV** - For simplicity

**Choose what works best for your workflow!** 🚀

---

## 📚 **Additional Resources**

- **Full Setup**: See `EMAIL_SYSTEM_READY.md`
- **Google Sheets Guide**: See `GOOGLE_SHEETS_EXCEL_GUIDE.md`
- **Quick Start**: See `QUICK_START_EMAIL.md`

---

**Happy inviting!** 📧✨


