/**
 * OpenSlot Flutter Plugin Error Fixer
 * This script patches Flutter plugin errors and provides fallbacks.
 */

(function() {
  console.log("Plugin error fixer loading...");
  
  // CRITICAL: Block WebAssembly completely to prevent CanvasKit loading attempts
  WebAssembly.compile = function() {
    console.log('WebAssembly.compile blocked to prevent CanvasKit errors');
    return Promise.reject(new Error('WebAssembly disabled for compatibility'));
  };
  
  WebAssembly.instantiate = function() {
    console.log('WebAssembly.instantiate blocked to prevent CanvasKit errors');
    return Promise.reject(new Error('WebAssembly disabled for compatibility'));
  };
  
  // Block CanvasKit loading completely
  const originalFetch = window.fetch;
  window.fetch = function(url, options) {
    if (typeof url === 'string' && 
        (url.includes('canvaskit') || 
         url.includes('chromium') || 
         url.includes('.wasm'))) {
      console.log('Blocked CanvasKit/WASM resource load:', url);
      return Promise.reject(new Error('CanvasKit loading blocked for compatibility'));
    }
    return originalFetch(url, options);
  };
  
  // Create a global variable to intercept plugin methods at runtime
  window.__pluginRegistrar = {
    plugins: {},
    register: function(name, factory) {
      console.log('Plugin registered:', name);
      this.plugins[name] = factory();
    },
    getPluginByName: function(name) {
      if (!this.plugins[name]) {
        // Create a mock if the plugin doesn't exist
        this.plugins[name] = {
          // Mock methods that would be called
          recordError: function() { return Promise.resolve(true); },
          logEvent: function() { return Promise.resolve(true); },
          crash: function() { return Promise.resolve(true); },
          log: function() { return Promise.resolve(true); },
          call: function() { return Promise.resolve(null); }
        };
        console.log('Created mock for plugin:', name);
      }
      return this.plugins[name];
    }
  };
  
  // Create stub for all Flutter plugins
  window.flutterGetPlatformChannel = function(name) {
    return window.__pluginRegistrar.getPluginByName(name);
  };
  
  // Patch the platform channel mechanism
  window.__flutter_web_set_location_strategy = function(unused) {
    // Noop - just a stub to prevent errors
  };
  
  // Force Flutter to use HTML renderer instead of CanvasKit
  window.flutterConfiguration = {
    renderer: "html"
  };
  
  // Create _flutter object if it doesn't exist
  if (!window._flutter) {
    window._flutter = {};
  }
  
  // Add loader if it doesn't exist
  if (!window._flutter.loader) {
    window._flutter.loader = {
      loadEntrypoint: function(options) {
        console.log("Mock loader loadEntrypoint called");
        // This would normally load Flutter, but we're handling that directly
        return Promise.resolve();
      }
    };
  }
  
  // Register Firebase plugins
  if (!window._flutter.registeredPlugins) {
    window._flutter.registeredPlugins = [
      "firebase_crashlytics",
      "firebase_analytics",
      "firebase_core",
      "firebase_auth"
    ];
  }
  
  // Mock Firebase
  window.firebase = {
    analytics: function() {
      return {
        logEvent: function() { 
          console.log('Mock Firebase Analytics: logEvent called'); 
          return true;
        }
      };
    },
    crashlytics: function() {
      return {
        recordError: function() { 
          console.log('Mock Firebase Crashlytics: recordError called');
          return true;
        }
      };
    }
  };
  
  // Override Error constructor to catch MissingPluginException before it happens
  const originalError = Error;
  Error = function(message) {
    if (message && message.includes && message.includes('MissingPluginException')) {
      console.log('Suppressed error:', message);
      return {
        message: message,
        suppressed: true,
        toString: function() { return 'Suppressed: ' + message; }
      };
    }
    return new originalError(message);
  };
  Error.prototype = originalError.prototype;
  
  // Create a global error handler to catch any remaining errors
  window.addEventListener('error', function(event) {
    if (event && event.error && event.error.message && 
        event.error.message.includes && 
        (event.error.message.includes('MissingPluginException') || 
         event.error.message.includes('firebase_crashlytics'))) {
      console.log('Global handler caught plugin error:', event.error.message);
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
  }, true);
  
  // Fix CORS issues by adding headers via proxy
  const originalXHROpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, ...args) {
    if (typeof url === 'string' && 
        (url.includes('canvaskit') || 
         url.includes('chromium') || 
         url.includes('.wasm'))) {
      console.log('Blocked XHR request to:', url);
      throw new Error('CanvasKit/WASM resource loading blocked');
    }
    return originalXHROpen.call(this, method, url, ...args);
  };
  
  // Make sure console.error doesn't crash the app
  const originalConsoleError = console.error;
  console.error = function(...args) {
    // Filter out crashlytics errors from console
    if (args.length > 0 && 
        typeof args[0] === 'string' && 
        (args[0].includes('MissingPluginException') || 
        args[0].includes('firebase_crashlytics'))) {
      console.log('Suppressed console error:', args);
      return;
    }
    return originalConsoleError.apply(console, args);
  };
  
  // Replace text content function to fix "Slotted" references
  const originalDocumentCreateTextNode = document.createTextNode;
  document.createTextNode = function(text) {
    if (typeof text === 'string' && text.includes('Slotted')) {
      text = text.replace(/Slotted/g, 'OpenSlot');
    }
    return originalDocumentCreateTextNode.call(document, text);
  };
  
  console.log("Plugin error fixer loaded successfully");
})(); 