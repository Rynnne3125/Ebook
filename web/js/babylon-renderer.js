// Babylon.js Renderer Service for Flutter Integration
class BabylonRenderer {
  constructor() {
    this.canvas = null;
    this.engine = null;
    this.scene = null;
    this.camera = null;
    this.models = new Map();
    this.animations = new Map();
    this.isInitialized = false;
  }

  // Initialize Babylon.js scene
  initialize(containerId, options = {}) {
    const container = document.getElementById(containerId);
    if (!container) {
      console.error('Container not found:', containerId);
      return false;
    }

    // Create canvas
    this.canvas = document.createElement('canvas');
    this.canvas.style.width = '100%';
    this.canvas.style.height = '100%';
    container.appendChild(this.canvas);

    // Initialize engine
    this.engine = new BABYLON.Engine(this.canvas, true, {
      preserveDrawingBuffer: true,
      stencil: true
    });

    // Create scene
    this.scene = new BABYLON.Scene(this.engine);
    this.scene.clearColor = new BABYLON.Color4(
      options.backgroundColor || 0.04, 
      options.backgroundColor || 0.05, 
      options.backgroundColor || 0.15, 
      1
    );

    // Create camera
    this.camera = new BABYLON.ArcRotateCamera(
      'camera',
      0,
      Math.PI / 3,
      5,
      BABYLON.Vector3.Zero(),
      this.scene
    );
    this.camera.attachControl(this.canvas, true);
    this.camera.lowerRadiusLimit = 1;
    this.camera.upperRadiusLimit = 10;
    this.camera.wheelDeltaPercentage = 0.01;

    // Setup lighting
    this.setupLighting(options.lighting);

    // Enable shadows
    this.scene.shadowsEnabled = true;

    // Render loop
    this.engine.runRenderLoop(() => {
      this.scene.render();
    });

    // Handle resize
    window.addEventListener('resize', () => {
      this.engine.resize();
    });

    this.isInitialized = true;
    return true;
  }

  // Setup lighting
  setupLighting(options = {}) {
    // Hemispheric light
    const hemisphericLight = new BABYLON.HemisphericLight(
      'hemisphericLight',
      new BABYLON.Vector3(0, 1, 0),
      this.scene
    );
    hemisphericLight.intensity = options.hemisphericIntensity || 0.4;
    hemisphericLight.groundColor = new BABYLON.Color3(0.1, 0.1, 0.2);

    // Directional light
    const directionalLight = new BABYLON.DirectionalLight(
      'directionalLight',
      new BABYLON.Vector3(-1, -2, -1),
      this.scene
    );
    directionalLight.intensity = options.directionalIntensity || 0.8;
    directionalLight.position = new BABYLON.Vector3(5, 5, 5);

    // Enable shadows
    directionalLight.shadowMinZ = 0.1;
    directionalLight.shadowMaxZ = 20;
    directionalLight.shadowMapSize = 2048;
    directionalLight.shadowEnabled = true;

    // Point light for accent
    const pointLight = new BABYLON.PointLight(
      'pointLight',
      new BABYLON.Vector3(-5, 3, 5),
      this.scene
    );
    pointLight.intensity = options.pointIntensity || 0.5;
    pointLight.range = 10;
  }

  // Load GLB/GLTF model
  loadModel(modelId, modelPath, options = {}) {
    return new Promise((resolve, reject) => {
      BABYLON.SceneLoader.ImportMesh(
        '',
        '',
        modelPath,
        this.scene,
        (meshes, particleSystems, skeletons) => {
          const model = new BABYLON.TransformNode(modelId, this.scene);
          
          // Add all meshes to the model
          meshes.forEach(mesh => {
            mesh.parent = model;
            
            // Enable shadows
            if (mesh.isMesh) {
              mesh.receiveShadows = true;
              mesh.castShadows = true;
            }
          });

          // Setup model properties
          if (options.scale) {
            model.scaling = new BABYLON.Vector3(options.scale, options.scale, options.scale);
          }
          if (options.position) {
            model.position = new BABYLON.Vector3(
              options.position.x || 0,
              options.position.y || 0,
              options.position.z || 0
            );
          }
          if (options.rotation) {
            model.rotation = new BABYLON.Vector3(
              options.rotation.x || 0,
              options.rotation.y || 0,
              options.rotation.z || 0
            );
          }

          this.models.set(modelId, {
            node: model,
            meshes: meshes,
            skeletons: skeletons
          });

          // Store animations
          if (skeletons && skeletons.length > 0) {
            this.animations.set(modelId, skeletons);
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
    const modelData = this.models.get(modelId);
    const skeletons = this.animations.get(modelId);
    
    if (!modelData || !skeletons || !skeletons[animationIndex]) {
      console.error('Animation not found:', modelId, animationIndex);
      return;
    }

    const skeleton = skeletons[animationIndex];
    const animationRanges = skeleton.getAnimationRanges();
    
    if (animationRanges && animationRanges.length > 0) {
      const range = animationRanges[animationIndex] || animationRanges[0];
      this.scene.beginAnimation(skeleton, range.from, range.to, loop);
    }
  }

  // Update model position
  updateModelPosition(modelId, position) {
    const modelData = this.models.get(modelId);
    if (modelData && modelData.node) {
      modelData.node.position = new BABYLON.Vector3(
        position.x || 0,
        position.y || 0,
        position.z || 0
      );
    }
  }

  // Update model rotation
  updateModelRotation(modelId, rotation) {
    const modelData = this.models.get(modelId);
    if (modelData && modelData.node) {
      modelData.node.rotation = new BABYLON.Vector3(
        rotation.x || 0,
        rotation.y || 0,
        rotation.z || 0
      );
    }
  }

  // Update model scale
  updateModelScale(modelId, scale) {
    const modelData = this.models.get(modelId);
    if (modelData && modelData.node) {
      modelData.node.scaling = new BABYLON.Vector3(scale, scale, scale);
    }
  }

  // Remove model
  removeModel(modelId) {
    const modelData = this.models.get(modelId);
    if (modelData) {
      // Dispose meshes
      modelData.meshes.forEach(mesh => {
        mesh.dispose();
      });
      
      // Dispose skeletons
      if (modelData.skeletons) {
        modelData.skeletons.forEach(skeleton => {
          skeleton.dispose();
        });
      }
      
      // Dispose node
      modelData.node.dispose();
      
      this.models.delete(modelId);
      this.animations.delete(modelId);
    }
  }

  // Add particle system
  addParticleSystem(particleId, options = {}) {
    const particleSystem = new BABYLON.ParticleSystem(particleId, options.particleCount || 1000, this.scene);
    
    // Configure particle system
    particleSystem.particleTexture = new BABYLON.Texture(options.texturePath || 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    particleSystem.emitter = new BABYLON.Vector3(0, 0, 0);
    particleSystem.minEmitBox = new BABYLON.Vector3(-1, -1, -1);
    particleSystem.maxEmitBox = new BABYLON.Vector3(1, 1, 1);
    
    particleSystem.color1 = new BABYLON.Color4(0.7, 0.8, 1.0, 1.0);
    particleSystem.color2 = new BABYLON.Color4(0.2, 0.5, 1.0, 1.0);
    particleSystem.colorDead = new BABYLON.Color4(0, 0, 0.2, 0.0);
    
    particleSystem.minSize = 0.1;
    particleSystem.maxSize = 0.5;
    
    particleSystem.minLifeTime = 0.3;
    particleSystem.maxLifeTime = 1.5;
    
    particleSystem.emitRate = options.emitRate || 500;
    particleSystem.blendMode = BABYLON.ParticleSystem.BLENDMODE_ONEONE;
    
    particleSystem.gravity = new BABYLON.Vector3(0, -9.81, 0);
    
    particleSystem.direction1 = new BABYLON.Vector3(-2, 8, 2);
    particleSystem.direction2 = new BABYLON.Vector3(2, 8, -2);
    
    particleSystem.minAngularSpeed = 0;
    particleSystem.maxAngularSpeed = Math.PI;
    
    particleSystem.minEmitPower = 1;
    particleSystem.maxEmitPower = 3;
    particleSystem.updateSpeed = 0.005;
    
    particleSystem.start();
    
    return particleSystem;
  }

  // Cleanup
  dispose() {
    if (this.scene) {
      this.scene.dispose();
    }
    if (this.engine) {
      this.engine.dispose();
    }
    this.models.clear();
    this.animations.clear();
    this.isInitialized = false;
  }
}

// Global instance
window.babylonRenderer = new BabylonRenderer();

// Flutter integration helpers
window.flutterBabylonRenderer = {
  initialize: (containerId, options) => window.babylonRenderer.initialize(containerId, options),
  loadModel: (modelId, modelPath, options) => window.babylonRenderer.loadModel(modelId, modelPath, options),
  playAnimation: (modelId, animationIndex, loop) => window.babylonRenderer.playAnimation(modelId, animationIndex, loop),
  updatePosition: (modelId, position) => window.babylonRenderer.updateModelPosition(modelId, position),
  updateRotation: (modelId, rotation) => window.babylonRenderer.updateModelRotation(modelId, rotation),
  updateScale: (modelId, scale) => window.babylonRenderer.updateModelScale(modelId, scale),
  removeModel: (modelId) => window.babylonRenderer.removeModel(modelId),
  addParticleSystem: (particleId, options) => window.babylonRenderer.addParticleSystem(particleId, options),
  dispose: () => window.babylonRenderer.dispose()
}; 