const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

const PORT = process.env.PORT || 3000;

// In-memory storage for messages (you could replace this with a database)
const channelMessages = {
    'general': [
        {
            avatar: 'SC',
            color: '#e74c3c',
            username: 'Sarah Chen',
            timestamp: 'Today at 9:23 AM',
            text: 'Good morning team! Ready for the product demo today? 🚀',
            reactions: ['👍 3', '🔥 1']
        },
        {
            avatar: 'MJ',
            color: '#3498db',
            username: 'Mike Johnson',
            timestamp: 'Today at 9:25 AM',
            text: 'Absolutely! I\'ve been working on the final touches for the UI. Everything should be ready by 2 PM.',
            thread: '2 replies'
        },
        {
            avatar: 'ED',
            color: '#9b59b6',
            username: 'Emma Davis',
            timestamp: 'Today at 9:31 AM',
            text: 'The marketing materials are all set too. Great work everyone! 📊',
            reactions: ['💯 2']
        },
        {
            avatar: 'AL',
            color: '#e67e22',
            username: 'Alex Liu',
            timestamp: 'Today at 10:15 AM',
            text: 'Quick question - should we include the performance metrics in today\'s demo, or save those for next week?'
        }
    ],
    'random': [
        {
            avatar: 'MJ',
            color: '#3498db',
            username: 'Mike Johnson',
            timestamp: 'Yesterday at 4:32 PM',
            text: 'Anyone else excited about the new coffee machine? ☕',
            reactions: ['☕ 5', '😍 2']
        }
    ],
    'development': [
        {
            avatar: 'AL',
            color: '#e67e22',
            username: 'Alex Liu',
            timestamp: 'Today at 8:15 AM',
            text: 'The new deployment pipeline is working great! Build time reduced by 40%.',
            reactions: ['🚀 4', '👏 2']
        }
    ],
    'design': [
        {
            avatar: 'ED',
            color: '#9b59b6',
            username: 'Emma Davis',
            timestamp: 'Today at 11:22 AM',
            text: 'Updated the design system with new color palette. Thoughts?',
            reactions: ['🎨 3', '👍 1']
        }
    ],
    'accounting-internal': [
        {
            avatar: 'JR',
            color: '#27ae60',
            username: 'Jennifer Rodriguez',
            timestamp: 'Today at 8:45 AM',
            text: 'Can someone send the updated Q2 personnel report by EOD?',
            reactions: ['✅ 1']
        },
        {
            avatar: 'BW',
            color: '#f39c12',
            username: 'Brian Wong',
            timestamp: 'Today at 9:12 AM',
            text: 'The vendor payment for TechCorp went through this morning. Invoice #A-2024-1156 is now closed.'
        },
        {
            avatar: 'MW',
            color: '#8e44ad',
            username: 'Maria Williams',
            timestamp: 'Today at 9:58 AM',
            text: 'Reminder: Tax filing deadline is next Friday. All department heads need to submit their final numbers by Wednesday.'
        },
        {
            avatar: 'DS',
            color: '#e74c3c',
            username: 'David Smith',
            timestamp: 'Today at 10:22 AM',
            text: 'Can someone double-check the reconciliation for the Morgan account? The numbers seem off by $2,400.',
            reactions: ['👀 1']
        }
    ]
};

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// API Routes
app.get('/api/messages/:channel', (req, res) => {
    const channel = req.params.channel;
    res.json(channelMessages[channel] || []);
});

app.post('/api/messages/:channel', (req, res) => {
    const channel = req.params.channel;
    const { message, username, avatar, color } = req.body;
    
    const now = new Date();
    const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    
    const newMessage = {
        avatar: avatar || 'YU',
        color: color || '#2ecc71',
        username: username || 'You',
        timestamp: `Today at ${timeString}`,
        text: message,
        id: Date.now() // Simple ID generation
    };
    
    if (!channelMessages[channel]) {
        channelMessages[channel] = [];
    }
    
    channelMessages[channel].push(newMessage);
    
    // Broadcast to all connected clients
    io.emit('newMessage', { channel, message: newMessage });
    
    res.json({ success: true, message: newMessage });
});

app.delete('/api/messages/:channel/:messageId', (req, res) => {
    const { channel, messageId } = req.params;
    
    if (channelMessages[channel]) {
        const messageIndex = channelMessages[channel].findIndex(msg => msg.id == messageId);
        if (messageIndex !== -1) {
            channelMessages[channel].splice(messageIndex, 1);
            io.emit('messageDeleted', { channel, messageId });
            res.json({ success: true });
        } else {
            res.status(404).json({ error: 'Message not found' });
        }
    } else {
        res.status(404).json({ error: 'Channel not found' });
    }
});

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);
    
    socket.on('joinChannel', (channel) => {
        socket.join(channel);
        console.log(`User ${socket.id} joined channel: ${channel}`);
    });
    
    socket.on('leaveChannel', (channel) => {
        socket.leave(channel);
        console.log(`User ${socket.id} left channel: ${channel}`);
    });
    
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Start server
server.listen(PORT, () => {
    console.log(`TeamChat server running on http://localhost:${PORT}`);
    console.log('Place your HTML file as "index.html" in the same directory as this server script');
});

module.exports = app;