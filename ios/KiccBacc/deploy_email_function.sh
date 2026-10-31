#!/bin/bash

# Deploy Email Invitation Cloud Function
# Run this after configuring Gmail credentials

echo "🚀 Deploying Email Invitation Function..."
echo ""

# Check if Firebase is configured
echo "📋 Current Firebase configuration:"
firebase functions:config:get
echo ""

# Deploy the function
echo "🔄 Deploying sendEventInvitationEmails..."
firebase deploy --only functions:sendEventInvitationEmails

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📧 Test by:"
echo "   1. Open KiccBacc app"
echo "   2. Go to any event → Event Properties → Import List"
echo "   3. Upload CSV with your email"
echo "   4. Send test invitation"
echo ""


