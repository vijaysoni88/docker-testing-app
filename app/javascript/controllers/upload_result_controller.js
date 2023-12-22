import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['container'];

  connect() {
    console.log('Connected to upload-result controller');
    this.updateContainer();
  }

  updateContainer() {
    console.log('Updating container');
    this.containerTarget.innerHTML = this.element.innerHTML;
  }
}
