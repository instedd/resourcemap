importWizardCallbacks = []
window.onImportWizard = (callback) -> importWizardCallbacks.push(callback)
window.runImportWizardCallbacks = -> callback() for callback in importWizardCallbacks
$ -> runImportWizardCallbacks() if $('#import-wizard-main').length > 0

importInProgressCallbacks = []
window.onImportInProgress = (callback) -> importInProgressCallbacks.push(callback)
window.runImportInProgressCallbacks = -> callback() for callback in importInProgressCallbacks
$ -> runImportInProgressCallbacks() if $('#import-in-progress').length > 0
