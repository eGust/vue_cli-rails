<template>
  <div id="app">
    <h1>Foo</h1>
    <HelloWorld msg="Vue!"></HelloWorld>
  </div>
</template>

<script>
import HelloWorld from '../components/HelloWorld.vue';

export default {
  name: 'Foo',
  components: { HelloWorld },
};
</script>

<style scoped>
h1 {
  color: red;
}
</style>
