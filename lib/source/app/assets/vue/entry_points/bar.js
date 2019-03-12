import Vue from 'vue';

import Bar from '../views/Bar.vue';

Vue.config.productionTip = false;

new Vue({
  render: h => h(Bar),
}).$mount('#app');
