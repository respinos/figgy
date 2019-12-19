import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/dist/system/system.css'
import 'lux-design-system/dist/system/tokens/tokens.scss'
import store from '../store'
import DocumentAdder from '../components/document_adder'
import PlaylistMembers from '../components/playlist_members'
import IssueMonograms from '../components/issue_monograms'
import axios from 'axios'
import OrderManager from '../components/OrderManager.vue'
import setupAuthLinkClipboard from '../packs/auth_link_clipboard.js'
import AjaxSelect from '../components/ajax-select'

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  // Set CSRF token for axios requests.
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  var elements = document.getElementsByClassName('lux')
  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i],
      store,
      components: {
        'document-adder': DocumentAdder,
        'playlistMembers': PlaylistMembers,
        'order-manager': OrderManager,
        'issue-monograms': IssueMonograms,
        'ajax-select': AjaxSelect
      },
      data: {
        options: []
      },
      methods: {
        onSearch(search, loading) {
          loading(true);
          this.search(loading, search, this);
        },
        search: _.debounce((loading, search, vm) => {
          fetch(
            `http://localhost:3000/catalog.json/?f%5Bhuman_readable_type_ssim%5D%5B%5D=Issue&q=figgy_title_ssi:*${escape(search)}`
          ).then(res => {
            res.json().then(json => (vm.options = json.response.docs));
            loading(false);
          });
        }, 350)
      }
    })
  }
  setupAuthLinkClipboard()
})
