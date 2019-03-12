<template>
  <div class="hello">
    <h2>Hello {{ msg }}</h2>
  </div>
</template>

<script>
export default {
  name: 'HelloWorld',
  props: {
    msg: String,
  },
};
</script>

<style scoped>
h2 {
  color: blue;
}
</style>
