### ComfyUI Installer
Manual install sucks. This script does it for you. Run it and done.  

---

### Quick Start
1. Run `scripts\install.bat`  
2. Open `C:\Users\me\Documents\ComfyUI\Comfy_UI.bat`  
3. Browser auto-opens at `http://127.0.0.1:8188`  
4. Optionally create a shortcut of Comfy_UI.bat and replace icon with `logo.ico` 

---

### Requirements
- Windows 10/11  
- NVIDIA GPU (tested on RTX 3090, 7800X3D)  
- Python 3.12.x  
- Internet  

---

### Includes
- PyTorch 2.7.1 + CUDA 12.8  
- FlashAttention (prebuilt wheel)  
- xFormers (prebuilt wheel)  
- InsightFace (prebuilt wheel)  
- SageAttention  
- DeepSpeed 0.16.4 (prebuilt wheel)  
- Triton 3.3.0.post19  
- ONNXRuntime-GPU  
- ComfyUI Manager, GGUF, Crystools  
- Launcher: `Comfy_UI.bat`  

---

### Troubleshooting
- No Git → [git-scm.com](https://git-scm.com/)  
- Python → [python.org](https://python.org/)  
- CUDA → 12.8 

---

### Config
Edit `config\constants.bat`  
Profiles:  
- `constants_2.7.bat` (default)  

---

**Run the script. It just works.**