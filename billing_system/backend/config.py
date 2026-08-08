"""
Application configuration.
All settings are centralised here so they can be overridden when migrating
to a database-backed deployment without touching any other file.
"""

class Config:
    # Flask
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 5000

    # CORS – explicit origins for browser-based Flutter web client.
    # The wildcard "*" is kept as fallback; the list covers common dev URLs.
    CORS_ORIGINS: list = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "*",
    ]

    # Billing
    # Invoice number format: 2026AUG08A1633  (YYYYMMMDDAHHMM)
    INVOICE_CONSTANT: str = "A"   # constant letter between date and time

    # GST slabs supported by the system
    GST_SLABS: list = [0, 5, 12, 18, 28]

    # Default price-list label shown in the billing header
    DEFAULT_PRICE_LIST: str = "Retail"

    # Company info (printed on bills)
    COMPANY_NAME: str = "My Shop"
    COMPANY_ADDRESS: str = "123 Main Street, City - 000000"
    COMPANY_PHONE: str = "+91 99999 99999"
    COMPANY_GSTIN: str = "29XXXXX0000X1ZX"
