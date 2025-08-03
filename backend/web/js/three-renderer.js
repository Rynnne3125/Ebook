// Three.js Renderer Service for Flutter Integration
class ThreeRenderer {
  constructor() {
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.controls = null;
    this.models = new Map();
    this.animations = new Map();
    this.isInitialized = false;
  }

  // Initialize Three.js scene
  initialize(containerId, options = {}) {
    const container = document.getElementById(containerId);
    if (!container) {
      console.error('Container not found:', containerId);
      return false;
    }

    // Scene setup
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(options.backgroundColor || 0x0a0e27);

    // Camera setup
    const aspect = container.clientWidth / container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
    this.camera.position.set(0, 2, 5);

    // Renderer setup
    this.renderer = new THREE.WebGLRenderer({ 
      antialias: true,
      alpha: options.alpha || false
    });
    this.renderer.setSize(container.clientWidth, container.clientHeight);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.outputEncoding = THREE.sRGBEncoding;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    
    container.appendChild(this.renderer.domElement);

    // Controls setup
    this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.enableZoom = options.enableZoom !== false;
    this.controls.enableRotate = options.enableRotate !== false;
    this.controls.enablePan = options.enablePan !== false;

    // Lighting
    this.setupLighting(options.lighting);

    // Animation loop
    this.animate();

    // Handle resize
    window.addEventListener('resize', () => this.onWindowResize(container));

    this.isInitialized = true;
    return true;
  }

  // Setup lighting
  setupLighting(options = {}) {
    // Ambient light
    const ambientLight = new THREE.AmbientLight(0x404040, options.ambientIntensity || 0.4);
    this.scene.add(ambientLight);

    // Directional light
    const directionalLight = new THREE.DirectionalLight(0xffffff, options.directionalIntensity || 0.8);
    directionalLight.position.set(5, 5, 5);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    this.scene.add(directionalLight);

    // Point light for accent
    const pointLight = new THREE.PointLight(0x667eea, options.pointIntensity || 0.5, 10);
    pointLight.position.set(-5, 3, 5);
    this.scene.add(pointLight);
  }

  // Load GLB/GLTF model
  loadModel(modelId, modelPath, options = {}) {
    return new Promise((resolve, reject) => {
      const loader = new THREE.GLTFLoader();
      
      // Setup DRACO loader for compression
      const dracoLoader = new THREE.DRACOLoader();
      dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.6/');
      loader.setDRACOLoader(dracoLoader);

      loader.load(
        modelPath,
        (gltf) => {
          const model = gltf.scene;
          
          // Setup model properties
          if (options.scale) {
            model.scale.setScalar(options.scale);
          }
          if (options.position) {
            model.position.set(options.position.x || 0, options.position.y || 0, options.position.z || 0);
          }
          if (options.rotation) {
            model.rotation.set(options.rotation.x || 0, options.rotation.y || 0, options.rotation.z || 0);
          }

          // Enable shadows
          model.traverse((child) => {
            if (child.isMesh) {
              child.castShadow = true;
              child.receiveShadow = true;
            }
          });

          this.scene.add(model);
          this.models.set(modelId, model);

          // Store animations
          if (gltf.animations && gltf.animations.length > 0) {
            this.animations.set(modelId, gltf.animations);
          }

          resolve(model);
        },
        (progress) => {
          console.log('Loading progress:', (progress.loaded / progress.total * 100) + '%');
        },
        (error) => {
          console.error('Error loading model:', error);
          reject(error);
        }
      );
    });
  }

  // Play animation
  playAnimation(modelId, animationIndex = 0, loop = true) {
    const model = this.models.get(modelId);
    const animations = this.animations.get(modelId);
    
    if (!model || !animations || !animations[animationIndex]) {
      console.error('Animation not found:', modelId, animationIndex);
      return;
    }

    const mixer = new THREE.AnimationMixer(model);
    const action = mixer.clipAction(animations[animationIndex]);
    action.setLoop(loop ? THREE.LoopRepeat : THREE.LoopOnce);
    action.play();

    // Store mixer for cleanup
    this.animations.set(`${modelId}_mixer`, mixer);
  }

  // Update model position
  updateModelPosition(modelId, position) {
    const model = this.models.get(modelId);
    if (model) {
      model.position.set(position.x || 0, position.y || 0, position.z || 0);
    }
  }

  // Update model rotation
  updateModelRotation(modelId, rotation) {
    const model = this.models.get(modelId);
    if (model) {
      model.rotation.set(rotation.x || 0, rotation.y || 0, rotation.z || 0);
    }
  }

  // Update model scale
  updateModelScale(modelId, scale) {
    const model = this.models.get(modelId);
    if (model) {
      model.scale.setScalar(scale);
    }
  }

  // Remove model
  removeModel(modelId) {
    const model = this.models.get(modelId);
    if (model) {
      this.scene.remove(model);
      this.models.delete(modelId);
      this.animations.delete(modelId);
      this.animations.delete(`${modelId}_mixer`);
    }
  }

  // Animation loop
  animate() {
    requestAnimationFrame(() => this.animate());

    // Update controls
    if (this.controls) {
      this.controls.update();
    }

    // Update animation mixers
    this.animations.forEach((value, key) => {
      if (key.includes('_mixer') && value) {
        value.update(0.016); // ~60fps
      }
    });

    // Render scene
    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }

  // Handle window resize
  onWindowResize(container) {
    if (this.camera && this.renderer) {
      const aspect = container.clientWidth / container.clientHeight;
      this.camera.aspect = aspect;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(container.clientWidth, container.clientHeight);
    }
  }

  // Cleanup
  dispose() {
    if (this.renderer) {
      this.renderer.dispose();
    }
    if (this.controls) {
      this.controls.dispose();
    }
    this.models.clear();
    this.animations.clear();
    this.isInitialized = false;
  }
}

// Global instance
window.threeRenderer = new ThreeRenderer();

// Flutter integration helpers
window.flutterThreeRenderer = {
  initialize: (containerId, options) => window.threeRenderer.initialize(containerId, options),
  loadModel: (modelId, modelPath, options) => window.threeRenderer.loadModel(modelId, modelPath, options),
  playAnimation: (modelId, animationIndex, loop) => window.threeRenderer.playAnimation(modelId, animationIndex, loop),
  updatePosition: (modelId, position) => window.threeRenderer.updateModelPosition(modelId, position),
  updateRotation: (modelId, rotation) => window.threeRenderer.updateModelRotation(modelId, rotation),
  updateScale: (modelId, scale) => window.threeRenderer.updateModelScale(modelId, scale),
  removeModel: (modelId) => window.threeRenderer.removeModel(modelId),
  dispose: () => window.threeRenderer.dispose()
}; 