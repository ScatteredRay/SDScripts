import http from 'http';
import express from 'express';
import optionator from 'optionator';
import Walk from '@root/walk';
import path from 'path';
import cors from 'cors';
import * as civitai from './civitai.js';

const app = express();
app.use(cors()); //!

const walk = Walk.create({
  withFileStats: true,
});

let modelTypes = [
    "checkpoints",
    "loras",
];

let modelExtensions = [
    '.safetensors',
    '.pth',
    '.ckpt',
    '.pt'
];

let dirs = {
};
for(let type of modelTypes) {  dirs[type] = []; console.log(`adding ${type}`, dirs[type]); };

let models = {
};
for(let type of modelTypes) { models[type] = {} };

async function updateModels(type) {
    if(!modelTypes.includes(type)) {
        throw Error(`Type ${type} unsupported`);
    }
    let paths = [];
    console.log(type);
    console.log(dirs[type]);
    await Promise.all(dirs[type].map(l => walk(l, async (e, p, d) => paths.push(p))));
    models[type] = {};
    for(let l of paths) {
        let ext = path.extname(l);
        if(!modelExtensions.includes(ext)) {
            continue;
        }
        models[type][path.basename(l,ext)] = l;
    }
}

async function checkUpdateModels(type) {
    console.log((type in models), Object.keys(models[type]));
    if(!(type in models) || Object.keys(models[type]).length === 0) {
        console.log("updateing");
        await updateModels(type);
    }
}

async function getModels(type) {
    await updateModels(type);
    return models[type];
}

function errorWrap(fn) {
    return async function(req, res, next) {
        try {
            return await fn(req, res, next);
        }
        catch(err) {
            next(err);
        }
    };
}

app.get('/api/models/:type', errorWrap(async (req, res) => {
    let data = Object.keys(await getModels(req.params.type));
    if(data.length === 0) {
        return res.status(404).send(`No models of type ${type} found`);
    }
    return res.send({
        items: data
    });
}));

app.get('/api/model/:name', errorWrap(async (req, res) => {
    let name = req.params.name;
    console.log(name);
    for(let type of modelTypes) {
        await checkUpdateModels(type);
        console.log(type);
        console.log(models[type]);
        if(name in models[type]) {
            let modelPath = models[type][name];
            console.log(modelPath);
            return res.send(await civitai.getModelMetaForFile(modelPath));
        }
    }
    return res.status(404).send(`Model ${name} not found`);
}));

let options = optionator({
    options : [
        {
            option: 'port',
            alias: 'p',
            type: 'Int',
            default: "8189"
        },
        {
            option: 'checkpoint',
            alias: 'c',
            type: '[String]',
            concatRepeatedArrays: true
        },
        {
            option: 'lora',
            alias: 'l',
            type: '[String]',
            concatRepeatedArrays: true
        }
    ]
}).parseArgv(process.argv);

if(options.checkpoint) {
    dirs.checkpoints = options.checkpoint;
}
if(options.lora) {
    dirs.loras = options.lora;
}

let server = http.createServer(app);
server.listen(options.port);