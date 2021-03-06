<template>
  <div class="lux-orderManager">
    <transition name="fade">
      <div
        v-if="loading"
        class="lux-overlay"
      >
        <loader size="medium" />
      </div>
    </transition>
    <alert
      v-if="saved"
      status="success"
      type="alert"
      autoclear
      dismissible
    >
      Your work has been saved!
    </alert>
    <alert
      v-if="saveError"
      status="error"
      type="alert"
      autoclear
      dismissible
    >
      Sorry, there was a problem saving your work!
    </alert>
    <wrapper
      :full-width="true"
      class="lux-galleryPanel"
      type="div"
    >
      <toolbar @cards-resized="resizeCards($event)" />
      <gallery
        class="lux-galleryWrapper"
        :card-pixel-width="cardPixelWidth"
        :gallery-items="galleryItems"
      />
    </wrapper>
    <wrapper
      class="lux-sidePanel"
      type="div"
      :full-width="false"
    >
      <!-- Resource Form-->
      <resource-form v-if="selectedTotal === 0" />
      <!-- Multiple Selected Form-->
      <filesets-form v-if="selectedTotal > 1" />
      <!-- Single Selected Form-->
      <fileset-form v-if="selectedTotal === 1" />
      <controls viewer-id="viewer" />
    </wrapper>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Controls from './OrderManagerControls'
import Toolbar from './OrderManagerToolbar'
import FilesetForm from './OrderManagerFilesetForm'
import FilesetsForm from './OrderManagerFilesetsForm'
import ResourceForm from './OrderManagerResourceForm'

/**
 * OrderManager is a tool for reordering thumbnails that represent members of a complex object (a book, CD, multi-volume work, etc.).
 * Complex patterns like OrderManager come with their own Vuex store that it needs to manage state.
 * The easiest way to use the OrderManager is to simply pass a resource in as a prop.
 * You can see how this is done in the live code example at the end of this section.
 *
 * However you will still need to load the corresponding
 * Vuex module, *resourceModule*. Please see [the state management documentation](/#!/State%20Management) for how to manage state in complex patterns.
 */
export default {
  name: 'OrderManager',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  components: {
    'toolbar': Toolbar,
    'resource-form': ResourceForm,
    'filesets-form': FilesetsForm,
    'fileset-form': FilesetForm,
    'controls': Controls
  },
  props: {
    /**
     * The resource object in json format.
     */
    resourceObject: {
      type: Object,
      default: null
    },
    /**
     * The resource id. Requires host app to have async lookup of resource.
     */
    resourceId: {
      type: String,
      default: null
    },
    defaultThumbnail: {
      type: String,
      default: 'https://picsum.photos/600/300/?random'
    }
  },
  data: function () {
    return {
      cardPixelWidth: 300,
      captionPixelPadding: 9
    }
  },
  computed: {
    galleryItems () {
      return this.resource.members.map(member => ({
        id: member.id,
        caption: member.label,
        service:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl
            : this.defaultThumbnail,
        mediaUrl:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl + '/full/300,/0/default.jpg'
            : this.defaultThumbnail,
        viewingHint: member.viewingHint
      }))
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
    isMultiVolume () {
      return this.$store.getters.isMultiVolume
    },
    ...mapState({
      resource: state => state.ordermanager.resource,
      gallery: state => state.gallery
    }),
    loading: function () {
      return this.resource.loadState !== 'LOADED'
    },
    saved () {
      return this.resource.saveState === 'SAVED'
    },
    saveError () {
      return this.resource.saveState === 'ERROR'
    }
  },
  beforeMount: function () {
    if (this.resourceObject) {
      // if props are passed in set the resource on mount
      this.$store.commit('SET_RESOURCE', this.resourceObject)
    } else {
      let resource = { id: this.resourceId }
      this.$store.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING')
      this.$store.dispatch('loadImageCollectionGql', resource)
    }
  },
  methods: {
    resizeCards: function (event) {
      this.cardPixelWidth = event.target.value
      if (this.cardPixelWidth < 75) {
        this.captionPixelPadding = 0
      } else {
        this.captionPixelPadding = 9
      }
    }
  }
}
</script>
<style lang="scss" scoped>
.lux-title {
  font-weight: bold;
}
.lux-orderManager {
  position: relative;
  height: 80vh;
}
.lux-orderManager /deep/ .lux-heading {
  margin: 12px 0 12px 0;
  line-height: 0.75;
  color: #001123;
}
.lux-orderManager /deep/ h2 {
  letter-spacing: 0;
  font-size: 24px;
}
.lux-sidePanel {
  position: absolute;
  top: 20px;
  right: 10px;
  height: 95%;
  width: 28.5%;
  border: 1px solid #ddd;
  border-radius: 4px;

  padding: 0 30px 0 30px;
  // height: 100%;
  overflow-y: scroll;
}
.lux-galleryPanel {
  position: absolute;
  top: 20px;
  left: 0;
  height: 95%;
  width: 70%;
  border-radius: 4px;
  border: 1px solid #ddd;
}
.lux-galleryWrapper {
  overflow: auto;
  height: calc(100% - 80px);
  border-radius: 4px;
  margin-bottom: 80px;
  clear: both;
}
</style>
