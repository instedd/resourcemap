window.onImportWizard ?= (callback) -> $(-> callback() if $('#import-wizard-main').length > 0)

window.onImportInProgress ?= (callback) -> $(-> callback() if $('#import-in-progress').length > 0)
