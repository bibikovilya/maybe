import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileName", "uploadArea", "uploadText"]

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", this.fileSelected.bind(this))
    }

    // Find the form element
    this.form = this.element.closest("form")
    if (this.form) {
      this.form.addEventListener("turbo:submit-start", this.formSubmitting.bind(this))
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("change", this.fileSelected.bind(this))
    }

    if (this.form) {
      this.form.removeEventListener("turbo:submit-start", this.formSubmitting.bind(this))
    }
  }

  triggerFileInput() {
    if (this.hasInputTarget) {
      this.inputTarget.click()
    }
  }

  fileSelected() {
    if (this.hasInputTarget && this.inputTarget.files.length > 0) {
      const fileCount = this.inputTarget.files.length
      const fileName = fileCount === 1
        ? this.inputTarget.files[0].name
        : `${fileCount} files selected`

      if (this.hasFileNameTarget) {
        // Find the paragraph element inside the fileName target
        const fileNameText = this.fileNameTarget.querySelector('p')
        if (fileNameText) {
          fileNameText.textContent = fileName
        }

        this.fileNameTarget.classList.remove("hidden")
        this.fileNameTarget.classList.add("flex")
      }

      if (this.hasUploadTextTarget) {
        this.uploadTextTarget.classList.add("hidden")
      }
    }
  }

  formSubmitting() {
    if (this.hasFileNameTarget && this.hasInputTarget && this.inputTarget.files.length > 0) {
      const fileCount = this.inputTarget.files.length
      const uploadingText = fileCount === 1
        ? `Uploading ${this.inputTarget.files[0].name}...`
        : `Uploading ${fileCount} files...`

      const fileNameText = this.fileNameTarget.querySelector('p')
      if (fileNameText) {
        fileNameText.textContent = uploadingText
      }

      // Change the icon to a loader
      const iconContainer = this.fileNameTarget.querySelector('.lucide-file-text')
      if (iconContainer) {
        iconContainer.classList.add('animate-pulse')
      }
    }

    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.classList.add("opacity-70")
    }
  }
}
