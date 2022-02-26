export class ElectronIpc {
    constructor() {
        if (!window.require) {
            return
        }
        const { ipcRenderer, shell } = window.require("electron")
        this.ipcRenderer = ipcRenderer
        this.shell = shell
    }

    send({ message } = {}) {
        if (!this.ipcRenderer) {
            return
        }
        this.ipcRenderer.send(message);
    }
    
    on({ event, callback } = {}) {
        if (!this.ipcRenderer) {
            return
        }
        this.ipcRenderer.on(event, (event, arg) => {
            callback()
        });
    }
    
    async openExternal({ url } = {}) {
        if (!this.shell) {
            return
        }
        await this.shell.openExternal(url)
    }
}
