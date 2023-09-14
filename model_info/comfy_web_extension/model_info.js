import { app } from "../scripts/app.js";
import { api } from "../scripts/api.js";
import { $el } from "../scripts/ui.js";

class ModelInfoAPI {
    constructor() {
        this.url = new URL(location);
        if(this.url.port.length > 0) {
            this.url.port = Number(this.url.port) + 1;
        }
        else {
            this.url.port = "8189";
        }
    }

    async listModels(type) {
        let resp = await fetch(this.url + `api/models/${type}`);
        let data = await resp.json();
        return data.items;
    }

    async modelInfo(name) {
        let resp = await fetch(this.url + `api/model/${name}`);
        let data = await resp.json();
        return data;
    }
};

class ModelInfo {
    name = "ModelInfo";
    ownMenu = false;
    modelTypes = [
        "checkpoints",
        "loras"
    ];
    selectedModel = null;

    createUI() {
        if(this.ownMenu) {
            this.menuContainer = $el("div.comfy-menu", {parent: document.body}, [
                $el("div.drag-handle", {
                    style: {
                        overflow: "hidden",
                        position: "relative",
                        width: "100%",
                        cursor: "default"
                    }
                }, [
                    $el("span.drag-handle"),
                    $el("span", {$: (q) => (this.queueSize = q)}),
                    $el("button.comfy-settings-btn", {textContent: "⚙️", onclick: () => console.log("click")}),
                ])
            ]);
        }
        else {
            this.menuContainer = app.ui.menuContainer;
        }

        this.modelButton = $el("button", {
            parent: this.menuContainer,
            textContent: "models",
            onclick: async (ev) => {
                //let nodeDefs = await api.getNodeDefs();
                //console.log(nodeDefs.CheckpointLoader);
                //console.log(nodeDefs.LoraLoader.input.required.lora_name);
                let modelMenu = new LiteGraph.ContextMenu(this.modelTypes, {
                    event: ev,
                    callback: async (v,e, p) => {
                        let type = v;
                        let modelList = await this.info.listModels(type);
                        let menu = new LiteGraph.ContextMenu(modelList, {
                            event: ev,
                            callback: (v, e, p) => {
                                this.selectModel(v);
                            },
                            parent: modelMenu
                        });
                    }
                });
            }
        });
    }

    async selectModel(name) {
        this.modelButton.textContent = name;
        this.selectedModel = name;
        this.selectedModelInfo = await this.info.modelInfo(name);
        console.log(this.selectedModelInfo);
    }

    init() {
        this.info = new ModelInfoAPI();
        this.createUI();
    }

    setup() {
    }
};

app.registerExtension(new ModelInfo());