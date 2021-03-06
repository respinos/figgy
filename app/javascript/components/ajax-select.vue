<template>
  <v-select label="id" :value="selected" @input=updateValue :filterable="false" :options="options" @search="onSearch">
    <template slot="no-options">
      type to search...
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
      default: '/catalog.json'
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
    const doc = document.getElementById(this.targetId)

    // Gets the current value of the input or a value passed as an attribute
    const id = doc.getAttribute('ajax_select_initial_id') || doc.value

    // Guard clause to return if no id is set
    if (id === '') { return }

    // Fetch the initial document and set that as the selected value
    this.query = `id:${id}`
    fetch(
      this.searchURL
    ).then(res => {
      return res.json()
    }).then(json => {
      const docs = json.response.docs
      if (docs.length > 0) {
        this.options = json.response.docs
        this.selected = this.options[0]
      }
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
    search: _.debounce((loading, query, vm) => {
      vm.query = `${query}*`
      fetch(
        vm.searchURL
      ).then(res => {
        res.json().then(json => (vm.options = json.response.docs))
        loading(false)
      })
    }, 350)
  }
}
</script>
<style lang="scss" scoped>
  img {
    height: auto;
    max-width: 2.5rem;
    margin-right: 1rem;
  }

  .d-center {
    display: flex;
    align-items: center;
  }

  .selected img {
    width: auto;
    max-height: 23px;
    margin-right: 0.5rem;
  }

  .v-select .dropdown li {
    border-bottom: 1px solid rgba(112, 128, 144, 0.1);
  }

  .v-select .dropdown li:last-child {
    border-bottom: none;
  }

  .v-select .dropdown li a {
    padding: 10px 20px;
    width: 100%;
    font-size: 1.25em;
    color: #3c3c3c;
  }

  .v-select .dropdown-menu .active > a {
    color: #fff;
  }
</style>
