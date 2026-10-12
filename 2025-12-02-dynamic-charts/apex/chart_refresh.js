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
      // Map the data if necessary, or use directly
      // Avoid logging sensitive response data to client console
      const mapped = pData.data.map(r => ({
        period: r.period,
        total:  r.total_sales
      }));
      
      // Example: Update a chart region if it supports setData
      // const chartRegion = apex.region("SALES_CHART");
      // chartRegion.setData(mapped);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      apex.message.clearErrors();
      // Show generic error message to avoid exposing raw technical details or stack traces
      apex.message.showErrors([
        {
          type: "error",
          message: "An error occurred while loading chart data.",
          location: ["page"]
        }
      ]);
    }
  }
);
