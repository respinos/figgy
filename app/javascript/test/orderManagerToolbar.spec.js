import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import OrderManagerToolbar from "../components/OrderManagerToolbar.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { modules } from 'lux-design-system'

// create an extended `Vue` constructor
const localVue = createLocalVue()
localVue.use(Vuex)

let wrapper
let getters
let options
let store
let actions
let items = [
  { id: "a", title: "A", viewingHint: "single", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
]

describe("OrderManagerToolbar.vue", () => {
  beforeEach(() => {
    actions = {
      cut: jest.fn(),
      paste: jest.fn(),
      select: jest.fn(),
    }

    const gallery = {
      state: {
        items: items,
        selected: [items[0]],
        cut: [],
        changeList: [],
        ogItems: items,
      },
      mutations: modules.galleryModule.mutations,
    }

    const getters = {
      getMemberCount: () => 3
    }

    const resource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "4609321",
          label: "Resource not available.",
          thumbnail: "",
          startCanvas: "",
          isMultiVolume: false,
          viewingHint: "single",
          viewingDirection: null,
          members: [],
          loadState: "NOT_LOADED",
          saveState: "NOT_SAVED",
          ogState: {},
        },
      },
      mutations: resourceMutations,
      getters: getters,
      actions: actions,
      modules: {
        gallery: gallery,
      },
    }

    store = new Vuex.Store({
      modules: {
        ordermanager: resource,
        gallery: gallery,
      },
    })

    options = {
      computed: {
        viewingDirection: function () {
          return 'bottom-to-top'
        },
        viewingHint: function () {
          return 'continuous'
        }
      }
    }

    wrapper = mount(OrderManagerToolbar, {
      options,
      localVue,
      store,
      stubs: ["dropdown-menu","lux-icon-base","lux-icon-picture","spacer"],
    })
  })

  it('selects all thumbnails when Select All button is clicked', () => {
    wrapper.vm.selectAll()
    expect(actions.select).toHaveBeenCalled()
  })

  it('selects alternate thumbnails when Select Alternate button is clicked', () => {
    wrapper.vm.selectAlternate()
    expect(actions.select).toHaveBeenCalled()
  })

  it('selects inverse thumbnails when Select Inverse button is clicked', () => {
    wrapper.vm.selectInverse()
    expect(actions.select).toHaveBeenCalled()
  })

  it('deselects all thumbnails when Select None button is clicked', () => {
    wrapper.vm.selectNone()
    expect(actions.select).toHaveBeenCalled()
  })

  it('cut and paste functions work', () => {
    wrapper.vm.cutSelected()
    expect(actions.cut).toHaveBeenCalled()
    wrapper.vm.paste()
    expect(actions.paste).toHaveBeenCalled()
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })
})
