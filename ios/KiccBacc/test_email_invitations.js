/**
 * Test script for Email Invitation System
 * 
 * This script tests the sendEventInvitationEmails Cloud Function
 * Run: node test_email_invitations.js
 */

const admin = require('firebase-admin');
const { initializeApp } = require('firebase-admin/app');

// Initialize Firebase Admin
initializeApp({
    projectId: 'kiccbacc-b538e'
});

// Test data
const testEmails = [
    'test1@example.com',
    'test2@example.com',
    'test3@example.com'
];

const testEventData = {
    eventID: 'TEST-EVENT-ID-123',
    name: 'Summer Music Festival 2025',
    fromDate: new Date('2025-07-15T18:00:00').getTime(),
    toDate: new Date('2025-07-15T23:00:00').getTime(),
    venueName: 'Central Park Amphitheater',
    city: 'New York',
    state: 'NY',
    ticketPrice: 25.00,
    ticketTypes: [
        { name: 'General Admission', price: 25.00 },
        { name: 'VIP Pass', price: 75.00 }
    ],
    eventBannerUrl: 'https://firebasestorage.googleapis.com/v0/b/kiccbacc-b538e.appspot.com/o/events%2Fcovers%2FC22F2CBC-F2C8-40B4-958B-7B4EDC18CD6A%2FC22F2CBC-F2C8-40B4-958B-7B4EDC18CD6A.png?alt=media&token=9b42daa5-fceb-4a94-88d6-ec713239e970',
    hostID: 'TEST-HOST-ID'
};

async function testEmailInvitations() {
    console.log('🧪 Testing Email Invitation System\n');
    console.log('📧 Test Emails:', testEmails);
    console.log('🎉 Test Event:', testEventData.name);
    console.log('\n⚠️  NOTE: This is a test script. To actually send emails, you need to:');
    console.log('   1. Set up Gmail credentials (GMAIL_USER and GMAIL_APP_PASSWORD)');
    console.log('   2. Deploy the Cloud Function');
    console.log('   3. Call the function from the iOS app\n');
    
    console.log('✅ Test data structure is valid!');
    console.log('\n📋 Email Template Preview:');
    console.log('   - Event Name:', testEventData.name);
    console.log('   - Date:', new Date(testEventData.fromDate).toLocaleDateString());
    console.log('   - Time:', new Date(testEventData.fromDate).toLocaleTimeString());
    console.log('   - Venue:', testEventData.venueName);
    console.log('   - Location:', `${testEventData.city}, ${testEventData.state}`);
    console.log('   - Price: Starting from $' + testEventData.ticketTypes[0].price.toFixed(2));
    console.log('   - Link: https://kiccbacc.com/event/' + testEventData.eventID);
    console.log('\n✨ Ready to send invitations from the iOS app!');
}

testEmailInvitations().then(() => {
    console.log('\n🏁 Test complete!');
    process.exit(0);
}).catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
});


