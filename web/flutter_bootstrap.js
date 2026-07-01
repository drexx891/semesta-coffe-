{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // Initialize the engine
    const appRunner = await engineInitializer.initializeEngine();
    
    // Run the app
    await appRunner.runApp();
    
    // Custom logic: Remove the custom loading screen after the app is running
    const loadingScreen = document.getElementById('loading-screen');
    if (loadingScreen) {
      loadingScreen.remove();
    }
  }
});
