export default class SaveAndIngestHandler {
  constructor () {
    this.button_element = $(this.buttonSelector)
    this.field_element = $(this.fieldElementSelector)
    this.info_element = $(this.infoElementSelector)
    this.resetButton()
    this.current_promise = null
    this.field_element.change((e) => {
      this.resetButton()
      this.button_element.val('Searching...')
      let change_set = window.location.pathname.split('/').pop()
      let qs = {}
      if (change_set !== 'new') {
        qs = { 'change_set': change_set }
      }
      if (this.current_promise) {
        this.current_promise.abort()
      }
      this.current_promise = $.getJSON(`/concern/scanned_resources/save_and_ingest/${this.field_element.val()}`, qs)
        .done((data) => {
          if (data.exists === true) {
            this.resetButton()
            this.button_element.prop('disabled', false)
            if (data.file_count != 0) { this.info_element.text(`Ingest ${data.file_count} files from ${data.location}`) } else { this.info_element.text(`Ingest ${data.volume_count} volumes from ${data.location}`) }
          } else {
            this.resetButton()
          }
        })
    })
  }

  resetButton () {
    this.button_element.attr('disabled', true)
    this.button_element.val('Save and Ingest')
    this.info_element.text('')
  }

  get buttonSelector () {
    return '*[data-save-and-ingest]'
  }

  get fieldElementSelector () {
    return "*[data-field='source_metadata_identifier_ssim']"
  }

  get infoElementSelector () {
    return '#save-and-ingest-info'
  }
}
