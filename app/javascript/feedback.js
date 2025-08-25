window.ATL_JQ_PAGE_PROPS = {
  "triggerFunction": function (showCollectorDialog) {
    document.getElementById("myCustomTrigger").addEventListener("click", function (e) {
      e.preventDefault();
      showCollectorDialog();
    });
  },
  "fieldValues": {
    components: ['15645'],
    email: document.getElementById("myCustomTrigger").getAttribute('data-email')
  }
};
