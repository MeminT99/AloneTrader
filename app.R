# Load necessary libraries
library(shiny)      # For building interactive web applications
library(quantmod)   # For financial quantitative modelling
library(forecast)   # For time series forecasting
library(plotly)     # For interactive plots

# Define UI for the Shiny application
ui <- fluidPage(
  # Add custom CSS styles for the UI elements
  tags$head(
    tags$style(HTML("
      /* Define custom styles for various UI elements */
      body {
        font-family: Arial, sans-serif;
        background-color: #f5f5f5;
      }
      /* Styles for the title */
      .title {
        color: #2c3e50;
        text-align: center;
        margin-bottom: 40px;
      }
      /* Styles for the sidebar */
      .sidebar {
        background-color: #ecf0f1;
        padding: 20px;
        border-radius: 10px;
      }
      /* Styles for the main panel */
      .main-panel {
        background-color: #ffffff;
        padding: 20px;
        border-radius: 10px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        margin-top: 20px;
      }
      /* Styles for the recommendation box */
      .recommendation-box {
        background-color: #3498db;
        color: #ffffff;
        padding: 20px;
        border-radius: 10px;
        text-align: center;
        font-weight: bold;
      }
      /* Styles for the stock statistics box */
      .stock-stats {
        margin-top: 20px;
        background-color: #ffffff;
        padding: 10px;
        border-radius: 10px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
      }
      /* Styles for headings inside stock statistics box */
      .stock-stats h4 {
        color: #2c3e50;
      }
      /* Styles for paragraphs inside stock statistics box */
      .stock-stats p {
        color: #2c3e50;
        margin: 0;
      }
    "))
  ),
  
  # Define the title panel
  titlePanel(div(class = "title", "AloneTrader")),
  
  # Define the layout for the sidebar and main panel
  sidebarLayout(
    sidebarPanel(
      class = "sidebar",
      # Select input for choosing stock symbol
      selectInput("stock", "Stock Symbol:", 
                  choices = c("Garanti Bankası" = "GARAN.IS", 
                              "Türk Hava Yolları" = "THYAO.IS", 
                              "Koç Holding" = "KCHOL.IS", 
                              "Türk Telekom" = "TTKOM.IS", 
                              "Emlak Konut" = "EKGYO.IS",
                              "Vestel Elektronik" = "VESTL.IS",
                              "Ford Otosan" = "FROTO.IS",
                              "Turkcell" = "TCELL.IS",
                              "Anadolu Efes" = "AEFES.IS",
                              "Petkim" = "PETKM.IS")),
      # Slider input for selecting forecast days
      sliderInput("days", "Forecast Days:", min = 7, max = 15, value = 7),
      # Stock statistics display box
      div(class = "stock-stats",
          h4("Stock Statistics"),
          p(textOutput("current_price")),
          p(textOutput("highest_price")),
          p(textOutput("lowest_price")),
          p(textOutput("average_price")),
          p(textOutput("market_cap")),
          p(textOutput("trading_volume"))
      )
    ),
    
    mainPanel(
      class = "main-panel",
      # Plotly output for displaying plot
      plotlyOutput("plot"),
      br(),
      # Recommendation box
      div(class = "recommendation-box", textOutput("recommendation"))
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Reactive expression to fetch stock data
  stock_data <- reactive({
    getSymbols(input$stock, from = "2022-01-01", to = Sys.Date(), auto.assign = FALSE)
  })
  
  # Reactive expression to convert stock data to time series
  ts_data <- reactive({
    as.ts(stock_data()[, 4])  
  })
  
  # Reactive expression to fit ARIMA model to the time series data
  arima_model <- reactive({
    auto.arima(ts_data(), seasonal = TRUE, lambda = "auto")
  })
  
  # Reactive expression to generate ARIMA forecast
  arima_forecast <- reactive({
    forecast(arima_model(), h = input$days)
  })
  
  # Render the plot using Plotly
  output$plot <- renderPlotly({
    plot_ly() %>%
      add_lines(x = index(stock_data()), y = ts_data(), name = "Actual", type = "scatter", mode = "lines",
                line = list(color = 'rgba(44, 62, 80, 1)')) %>%
      add_lines(x = seq.Date(from = Sys.Date(), length.out = input$days, by = 1), 
                y = arima_forecast()$mean, name = "Forecast", type = "scatter", mode = "lines",
                line = list(color = 'rgba(52, 152, 219, 1)')) %>%
      layout(title = list(text = paste(input$stock, "Stock Price Forecast"), y = 0.97),
             xaxis = list(title = "Date"),
             yaxis = list(title = "Price (₺)"),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#f5f5f5')
  })
  
  # Render recommendation based on forecast
  output$recommendation <- renderText({
    forecast_mean <- arima_forecast()$mean
    forecast_pct_change <- diff(forecast_mean) / head(forecast_mean, -1) * 100
    mean_pct_change <- mean(forecast_pct_change, na.rm = TRUE)
    
    if (mean_pct_change > 0) {
      "Recommendation: Buy"
    } else if (mean_pct_change < 0) {
      "Recommendation: Sell"
    } else {
      "Recommendation: Hold"
    }
  })
  
  # Render current price
  output$current_price <- renderText({
    price <- last(ts_data())
    if (!is.na(price))
      paste("Current Price: ₺", round(price, 2))
  })
  
  # Render highest price
  output$highest_price <- renderText({
    price <- max(ts_data(), na.rm = TRUE)
    if (!is.na(price))
      paste("Highest Price: ₺", round(price, 2))
  })
  
  # Render lowest price
  output$lowest_price <- renderText({
    price <- min(ts_data(), na.rm = TRUE)
    if (!is.na(price))
      paste("Lowest Price: ₺", round(price, 2))
  })
}
                                     
shinyApp(ui = ui, server = server)