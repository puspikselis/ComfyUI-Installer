### ComfyUI Installer
Manual install sucks. This script does it for you. Run it and done.  

---

### Quick Start
1. Run `scripts\install.bat` as administrator  
2. Open `%USERPROFILE%\Documents\ComfyUI\Comfy_UI.bat`  
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
- **No Git:** Download from [git-scm.com](https://git-scm.com/)  
- **Python Issues:** Install Python 3.12 from [python.org](https://python.org/)  
- **CUDA Errors:** Ensure NVIDIA drivers support CUDA 12.8+
- **Script Won't Run:** Right-click and "Run as administrator" 

---

### Config
Edit `config\constants.bat`  
Profiles:  
- `constants_2.7.bat` (default)  

---

### Uninstall & Cleanup
1. **First:** Use Windows "Add or Remove Programs" to uninstall Python
2. **Then:** Run `scripts\uninstall.bat` to clean up ComfyUI and leftover files
3. **Finally:** Run `scripts\cleanup.bat` to remove remaining registry entries and temp files




---

**Run the script. It just works.**