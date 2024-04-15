// Global scripts
__SFC_SCRIPTS__

// Vue SFC Loader options
const options = {
    moduleCache: {
        vue: Vue,
        'vue-router': VueRouter    },
    async getFile(url) {
        const res = await fetch(url);
        if ( !res.ok )
            throw Object.assign(new Error(res.statusText + ' ' + url), { res });
        return {
            getContentData: asBinary => asBinary ? res.arrayBuffer() : res.text(),
        }
    },
    addStyle(textContent) {
        const style = Object.assign(document.createElement('style'), { textContent });
        const ref = document.head.getElementsByTagName('style')[0] || null;
        document.head.insertBefore(style, ref);
    },
}

// Instantiate components
__SFC_COMPONENT_INST__

// Define routes
const routes = [
    __SFC_ROUTES__]

// Initialize Vue Router
const router = VueRouter.createRouter({
    history: VueRouter.createWebHistory(),
    routes: routes
});

// Load Vue SFC Loader
const { loadModule } = window['vue3-sfc-loader'];

// Instantiate Vuetify
const vuetify = Vuetify.createVuetify()

// Instantiate app
const app = Vue.createApp({
    template: `<__SFC_PLACEHOLDER__ __SFC_PROPS__/>`,
    components: {
        __SFC_COMPONENT_DECL__
    }
});
app.use(router);
app.use(vuetify);
router.isReady().then(() => app.mount('#app'));
