// chart_refresh.js
// JavaScript code for the Dynamic Action (Execute JavaScript Code)

apex.server.process(
  "GET_SALES_DATA", // Process Name (must match the AJAX Callback name)
  {
    x01: $v('P10_YEAR'),
    x02: $v('P10_REGION')
  },
  {
    success: function(pData) {
      console.log("Response:", pData);

      // Map the data if necessary, or use directly
      const mapped = pData.data.map(r => ({
        period: r.period,
        total:  r.total_sales
      }));
      
      console.log("Mapped Data:", mapped);
      
      // Example: Update a chart region if it supports setData
      // const chartRegion = apex.region("SALES_CHART");
      // chartRegion.setData(mapped);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      apex.message.clearErrors();
      apex.message.showErrors([
        {
          type: "error",
          message: "Request failed: " + errorThrown,
          location: ["page"]
        }
      ]);
    }
  }
);
