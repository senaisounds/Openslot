# Slotted App Manual Test Checklist

## Login & Authentication
- [ ] Open app and see splash screen with "OPEN SLOT" animation
- [ ] Navigate to login screen
- [ ] Sign in with existing credentials
- [ ] Try incorrect credentials (should show error)
- [ ] Test password reset flow
- [ ] Navigate to Profile page when not logged in to verify login prompt appears

## Home Page
- [ ] Check that the new Openslot logo appears properly
- [ ] Verify featured events are displaying
- [ ] Test category filtering functionality
- [ ] Test date filtering (Today/Tomorrow/This Weekend)
- [ ] Scroll behavior and navigation bar responsiveness
- [ ] Verify search functionality

## Event Creation
- [ ] Navigate to event creation flow
- [ ] Fill out all fields with valid data
- [ ] Test location selection (previously fixed issue)
- [ ] Upload event image
- [ ] Set price and slots
- [ ] Submit event and verify it appears in listings

## Event Details
- [ ] View event details for an event
- [ ] Test reservation functionality
- [ ] Verify reservation confirmation
- [ ] Check attendance list if you're the organizer
- [ ] Test cancellation flow

## User Profile
- [ ] View profile information
- [ ] Edit profile details
- [ ] Check saved/favorited events
- [ ] Verify hosted events appear in My Events
- [ ] Log out and verify login prompt appears on profile page
- [ ] Test the Sign In button on profile login prompt

## Maps & Location
- [ ] Test map view of events
- [ ] Verify event markers appear correctly
- [ ] Test location selection for event creation

## Chat & Notifications
- [ ] Check event chat functionality
- [ ] Verify notifications are received and displayed

## Critical Bug Verification
- [ ] Verify location selection doesn't exit creation flow prematurely
- [ ] Check that the app always uses dark mode theme
- [ ] Verify custom splash screen displays correctly with animation
- [ ] Verify profile page shows login prompt for unauthenticated users

## Performance Checks
- [ ] Check app startup time
- [ ] Verify smooth scrolling on event lists
- [ ] Test responsiveness when navigating between screens 