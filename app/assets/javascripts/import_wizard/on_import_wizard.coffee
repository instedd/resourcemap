window.onImportWizard ?= (callback) -> $(-> callback() if $('#import-wizard-main').length > 0)
