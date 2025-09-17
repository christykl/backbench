#!/usr/bin/env python3
"""
Fake Stock Trading Server
Run with: echo password | sudo -u user pm2 start app.py --interpreter=python
"""

from flask import Flask, request, jsonify
import threading
import time
import random
import json
import os
from datetime import datetime

app = Flask(__name__)

# Stock data with moving averages
STOCKS = {
    'AAPL': {'name': 'Apple Inc.', 'price': 50.0, 'ma': 20.0},
    'GOOGL': {'name': 'Alphabet Inc.', 'price': 2500.0, 'ma': 2500.0},
    'MSFT': {'name': 'Microsoft Corp.', 'price': 300.0, 'ma': 300.0},
    'AMZN': {'name': 'Amazon.com Inc.', 'price': 3200.0, 'ma': 3200.0},
    'TSLA': {'name': 'Tesla Inc.', 'price': 800.0, 'ma': 800.0},
    'META': {'name': 'Meta Platforms Inc.', 'price': 320.0, 'ma': 320.0},
    'NVDA': {'name': 'NVIDIA Corp.', 'price': 450.0, 'ma': 450.0},
    'NFLX': {'name': 'Netflix Inc.', 'price': 400.0, 'ma': 400.0},
    'BABA': {'name': 'Alibaba Group', 'price': 90.0, 'ma': 90.0},
    'AMD': {'name': 'Advanced Micro Devices', 'price': 120.0, 'ma': 120.0}
}

# User portfolios - stores cash, stock holdings, and transaction history
USERS = {}
DATA_FILE = 'trading_data.json'

def load_data():
    """Load user data from file"""
    global USERS
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
                USERS = data.get('users', {})
        except:
            USERS = {}

def save_data():
    """Save user data to file"""
    data = {'users': USERS}
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def initialize_trader1():
    """Initialize trader1 with pre-existing AAPL position"""
    if 'trader1' not in USERS:
        # Buy 100 AAPL at $160 (higher than current $150 average)
        initial_aapl_price = 170.0
        initial_quantity = 50
        initial_cost = initial_aapl_price * initial_quantity
        setuptime = datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%f')

        USERS['trader1'] = {
            'cash': 10000.0 - initial_cost,  # Starting cash minus AAPL purchase
            'stocks': {'AAPL': initial_quantity},
            'transactions': [{
                'id': 1,
                'type': 'BUY',
                'symbol': 'AAPL',
                'quantity': initial_quantity,
                'price': initial_aapl_price,
                'total': initial_cost,
                'timestamp': setuptime,  # time on setup script run
                'note': 'Initial position'
            }],
            'created': setuptime
        }
        save_data()
        print(f"Initialized trader1 with {initial_quantity} AAPL shares at ${initial_aapl_price}")

def get_or_create_user(username):
    """Get user or create new user with starting cash"""
    if username not in USERS:
        USERS[username] = {
            'cash': 10000.0,  # Starting cash
            'stocks': {},     # Stock holdings
            'transactions': [],  # Transaction history
            'created': datetime.now().isoformat()
        }
        save_data()
    return USERS[username]

def add_transaction(username, transaction_type, symbol, quantity, price, note=""):
    """Add transaction to user's history"""
    user = USERS[username]
    if 'transactions' not in user:
        user['transactions'] = []
    
    # Get next transaction ID
    next_id = max([t.get('id', 0) for t in user['transactions']], default=0) + 1
    
    transaction = {
        'id': next_id,
        'type': transaction_type,
        'symbol': symbol,
        'quantity': quantity,
        'price': round(price, 2),
        'total': round(price * quantity, 2),
        'timestamp': datetime.now().isoformat(),
        'note': note
    }
    
    user['transactions'].append(transaction)
    save_data()

def update_stock_prices():
    """Update stock prices every second around moving average"""
    while True:
        for symbol, data in STOCKS.items():
            # Random walk around moving average
            volatility = 0.02  # 2% volatility
            change = random.gauss(0, volatility)
            
            # Pull price towards moving average (mean reversion)
            reversion_strength = 0.1
            ma_pull = (data['ma'] - data['price']) * reversion_strength
            
            # Update price
            new_price = data['price'] * (1 + change) + ma_pull
            data['price'] = max(0.01, new_price)  # Prevent negative prices
            
            # Slowly drift moving average
            data['ma'] += random.gauss(0, 0.001) * data['ma']
        
        time.sleep(1)

# Start price update thread
price_thread = threading.Thread(target=update_stock_prices, daemon=True)
price_thread.start()

# Load existing data and initialize trader1
load_data()
initialize_trader1()

@app.route('/api/stocks', methods=['GET'])
def get_stocks():
    """Get all stock prices"""
    return jsonify({
        'stocks': {symbol: {
            'name': data['name'],
            'price': round(data['price'], 2)
        } for symbol, data in STOCKS.items()}
    })

@app.route('/api/user/<username>', methods=['GET'])
def get_user(username):
    """Get user portfolio"""
    user = get_or_create_user(username)
    return jsonify({
        'username': username,
        'cash': round(user['cash'], 2),
        'stocks': user['stocks'],
        'total_value': round(user['cash'] + sum(
            STOCKS[symbol]['price'] * quantity 
            for symbol, quantity in user['stocks'].items()
            if symbol in STOCKS
        ), 2),
        'transactions': user.get('transactions', [])
    })

@app.route('/api/transactions/<username>', methods=['GET'])
def get_transactions(username):
    """Get user's transaction history"""
    if username not in USERS:
        return jsonify({'transactions': []})
    
    user = USERS[username]
    transactions = user.get('transactions', [])
    
    # Sort by timestamp (newest first)
    transactions_sorted = sorted(transactions, key=lambda x: x['timestamp'], reverse=True)
    
    return jsonify({'transactions': transactions_sorted})

@app.route('/api/buy', methods=['POST'])
def buy_stock():
    """Buy stocks"""
    data = request.get_json()
    username = data.get('username')
    symbol = data.get('symbol')
    quantity = data.get('quantity', 1)
    
    if not username or not symbol:
        return jsonify({'error': 'Username and symbol required'}), 400
    
    if symbol not in STOCKS:
        return jsonify({'error': 'Stock not found'}), 404
    
    if quantity <= 0:
        return jsonify({'error': 'Quantity must be positive'}), 400
    
    user = get_or_create_user(username)
    stock_price = STOCKS[symbol]['price']
    total_cost = stock_price * quantity
    
    if user['cash'] < total_cost:
        return jsonify({'error': 'Insufficient funds'}), 400
    
    # Execute trade
    user['cash'] -= total_cost
    user['stocks'][symbol] = user['stocks'].get(symbol, 0) + quantity
    
    # Add transaction to history
    add_transaction(username, 'BUY', symbol, quantity, stock_price)
    
    return jsonify({
        'message': f'Bought {quantity} shares of {symbol}',
        'price': round(stock_price, 2),
        'total_cost': round(total_cost, 2),
        'remaining_cash': round(user['cash'], 2)
    })

@app.route('/api/sell', methods=['POST'])
def sell_stock():
    """Sell stocks"""
    data = request.get_json()
    username = data.get('username')
    symbol = data.get('symbol')
    quantity = data.get('quantity', 1)
    
    if not username or not symbol:
        return jsonify({'error': 'Username and symbol required'}), 400
    
    if symbol not in STOCKS:
        return jsonify({'error': 'Stock not found'}), 404
    
    if quantity <= 0:
        return jsonify({'error': 'Quantity must be positive'}), 400
    
    user = get_or_create_user(username)
    
    if symbol not in user['stocks'] or user['stocks'][symbol] < quantity:
        return jsonify({'error': 'Insufficient shares'}), 400
    
    # Execute trade
    stock_price = STOCKS[symbol]['price']
    total_value = stock_price * quantity
    
    user['cash'] += total_value
    user['stocks'][symbol] -= quantity
    
    # Remove stock if quantity is 0
    if user['stocks'][symbol] == 0:
        del user['stocks'][symbol]
    
    # Add transaction to history
    add_transaction(username, 'SELL', symbol, quantity, stock_price)
    
    return jsonify({
        'message': f'Sold {quantity} shares of {symbol}',
        'price': round(stock_price, 2),
        'total_value': round(total_value, 2),
        'new_cash': round(user['cash'], 2)
    })

@app.route('/api/quote/<symbol>', methods=['GET'])
def get_quote(symbol):
    """Get single stock quote"""
    if symbol not in STOCKS:
        return jsonify({'error': 'Stock not found'}), 404
    
    stock = STOCKS[symbol]
    return jsonify({
        'symbol': symbol,
        'name': stock['name'],
        'price': round(stock['price'], 2)
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'running', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    print("Starting fake stock trading server...")
    print("Available stocks:", list(STOCKS.keys()))
    app.run(host='0.0.0.0', port=5001, debug=False)