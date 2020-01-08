<template>
  <v-select label="id" :value="selected" @input=updateValue :filterable="false" :options="options" @search="onSearch">
    <template slot="no-options">
      type to search for numismatic places...
    </template>
    <template slot="option" slot-scope="option">
      <div class="d-center">
        {{ option["figgy_title_ssi"] }}
        </div>
    </template>
    <template slot="selected-option" slot-scope="option">
      <div class="selected d-center">
        {{ option["figgy_title_ssi"] }}
      </div>
    </template>
  </v-select>
</template>
<script>
import vSelect from 'vue-select'
import _ from 'lodash'
export default {
  name: 'AjaxSelect',
  components: {
    'v-select': vSelect
  },
  props: {
    typeName: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      options: [],
      selected: null
    }
  },
  methods: {
    updateValue (value) {
      value = value || { id: null }
      document.getElementById('numismatics_coin_find_place_id').value = value.id
      this.selected = value
    },
    searchURL (search) {
      return `http://localhost:3000/catalog.json/?f%5Bhuman_readable_type_ssim%5D%5B%5D=${this.typeName}&all_models=true&q=${escape(search)}`
    },
    onSearch (search, loading) {
      loading(true)
      this.search(loading, search, this)
    },
    search: _.debounce((loading, search, vm) => {
      fetch(
        vm.searchURL(search)
      ).then(res => {
        res.json().then(json => (vm.options = json.response.docs))
        loading(false)
      })
    }, 350)
  }
}
</script>
