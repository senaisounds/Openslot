# Open Slot - Web Version

This is the web version of the Open Slot app. It uses the Flutter HTML renderer for optimal text rendering and performance.

## Building the Web App

To build the web app for production:

```bash
# Normal build
./build_web.sh

# Clean build (recommended for full rebuilds)
./build_web.sh --clean
```

The built web app will be available in the `build/web` directory.

## Testing Locally

To test the built web app locally:

```bash
# First build the app
./build_web.sh

# Then serve it locally
./serve_web.sh
```

Then open http://localhost:8000 in your browser.

## Deployment

The contents of the `build/web` directory can be deployed to any web hosting service, such as:

- Firebase Hosting
- GitHub Pages
- Netlify
- Vercel
- Amazon S3
- Any standard web server

### Example: Firebase Hosting Deployment

```bash
# Install Firebase CLI if you haven't already
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (first time only)
firebase init hosting

# Deploy to Firebase
firebase deploy --only hosting
```

## Important Notes

1. This web version is optimized to use the HTML renderer and system fonts to ensure text displays properly.

2. The iOS app is completely separate and won't be affected by any changes made to the web version.

3. If text display issues occur:
   - Ensure that the web app is using the HTML renderer
   - Check that the system fonts fallback is properly configured in index.html 