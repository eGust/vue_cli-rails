<template>
  <div id="app">
    <slot></slot>
  </div>
</template>

<script>
export default {
  name: 'App',
};
</script>

<style>
#app {
  box-sizing: border-box;
}

#app * {
  box-sizing: border-box;
}
</style>
