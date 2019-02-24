import Vue from 'vue';

import App from './App.vue';

Vue.config.productionTip = false;

export default Component => new Vue({
  render: h => h(App, { scopedSlots: { default: () => h(Component) } }),
}).$mount('#app');
