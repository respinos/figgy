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
    },
    targetId: {
      type: String,
      required: true
    },
    searchURLBase: {
      type: String,
      default: '/catalog.json/'
    }
  },
  data () {
    return {
      options: [],
      selected: null,
      query: null
    }
  },
  computed: {
    searchURL: function () {
      return `${this.searchURLBase}/?f%5Bhuman_readable_type_ssim%5D%5B%5D=${this.typeName}&all_models=true&q=${escape(this.query)}`
    }
  },
  created: function () {
    const id = `id:${document.getElementById(this.targetId).value}`
    this.query = id

    const results = fetch(
      this.searchURL
    ).then(res => {
      return res.json()
    }).then(json => {
      console.log(json)
      this.options = json.response.docs
      // We are not handling empty results here
      this.selected = this.options[0]
    })
  },
  methods: {
    updateValue (value) {
      value = value || { id: null }
      const target = document.getElementById(this.targetId)
      target.value = value.id
      this.selected = value
    },
    onSearch (search, loading) {
      loading(true)
      this.search(loading, search, this)
    },
    retrieve (query) {
      this.query = query

      const p = fetch(
        this.searchURL
      ).then(res => {
        res.json().then(json => {
          debugger
          // This needs to be restructured
          return json.response.docs
        })
      }).then(data => data)
      debugger
      return p
    },
    search: _.debounce((loading, query, vm) => {
      vm.query = query
      fetch(
        vm.searchURL
      ).then(res => {
        res.json().then(json => vm.options = json.response.docs)
        loading(false)
      })
    }, 350)
  }
}
</script>
