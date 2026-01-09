# Action Cable: Complete Reference Guide for Claude Code Agent

## Overview

Action Cable is a Rails framework that seamlessly integrates WebSockets with your Rails application, enabling real-time features like live notifications, presence tracking, and collaborative updates. It provides both server-side Ruby and client-side JavaScript frameworks for building interactive applications.

**Key Context**: Action Cable allows bidirectional communication between server and client without the traditional HTTP request-response cycle.

---

## Core Concepts and Terminology

### Fundamental Components

**Connections**: Form the foundation of the client-server relationship. A single Action Cable server can handle multiple connection instances. One connection instance exists per WebSocket connection. A single user may have multiple WebSockets open (multiple tabs/devices).

**Consumers**: The client-side of a WebSocket connection. Created by the client-side JavaScript framework (`createConsumer()`). Each consumer can subscribe to one or more channels.

**Channels**: Encapsulate logical units of work, similar to controllers in MVC. Each channel is a logical workspace (e.g., ChatChannel, AppearanceChannel). A consumer can subscribe to multiple channels simultaneously.

**Subscribers**: When a consumer subscribes to a channel, it becomes a subscriber. The connection between subscriber and channel is called a subscription. A consumer can act as a subscriber to the same channel multiple times.

**Pub/Sub**: Publish-Subscribe message queue paradigm. Senders (publishers) send data to recipients (subscribers) without specifying individual recipients. Action Cable uses this approach for server-client communication.

**Broadcastings**: A pub/sub link where anything transmitted by publisher goes directly to channel subscribers. Each channel can stream zero or more broadcastings. Broadcastings are purely online and time-dependent - if a consumer isn't subscribed when data is broadcast, they won't receive it upon reconnection.

---

## Server-Side Implementation

### Connection Setup (`app/channels/application_cable/connection.rb`)

The connection class handles WebSocket authentication and authorization:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.name
    end

    protected
    def find_verified_user
      if verified_user = User.find_by(id: cookies.signed[:user_id])
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

**Key Points**:

- `identified_by :current_user` declares a connection identifier for later retrieval
- Authentication happens through cookies (encrypted or signed)
- Must return a verified user or reject the connection
- Only works with cookie-based authentication (WebSocket doesn't have session access)

### Connection Lifecycle Callbacks

Available hooks for handling connection events:

- `before_command`: Fired before any command
- `after_command`: Fired after any command
- `around_command`: Wraps command execution

### Channel Base Class (`app/channels/application_cable/channel.rb`)

```ruby
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

All custom channels inherit from this base class for shared logic.

### Custom Channels

Example channel for comments:

```ruby
class CommentsChannel < ApplicationCable::Channel
  def follow(data)
    stop_all_streams
    stream_from "messages:#{data['message_id'].to_i}:comments"
  end

  def unfollow
    stop_all_streams
  end
end
```

**Channel Lifecycle Methods**:

- `subscribed`: Called when consumer successfully subscribes
- `unsubscribed`: Called when consumer unsubscribes
- `receive(data)`: Called when client sends data via `send()`

**Channel Lifecycle Callbacks**:

- `before_subscribe`: Before subscription is accepted
- `after_subscribe` / `on_subscribe`: After subscription is accepted
- `before_unsubscribe`: Before unsubscription
- `after_unsubscribe` / `on_unsubscribe`: After unsubscription

### Streaming and Broadcasting

**Stream From** (individual stream):

```ruby
def subscribed
  stream_from "chat_#{params[:room]}"
end
```

Elsewhere in your app, broadcast to this stream:

```ruby
ActionCable.server.broadcast("chat_Best Room", { body: "Message" })
```

**Stream For** (model-based stream):

```ruby
def subscribed
  post = Post.find(params[:id])
  stream_for post
end
```

Broadcast to model stream:

```ruby
PostsChannel.broadcast_to(@post, @comment)
```

### Exception Handling

Global exception handling on connections:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    private
    def report_error(e)
      SomeExternalBugtrackingService.notify(e)
    end
  end
end
```

Channel-specific exception handling:

```ruby
class ChatChannel < ApplicationCable::Channel
  rescue_from "MyError", with: :deliver_error_message

  private
  def deliver_error_message(e)
    broadcast_to(...)
  end
end
```

---

## Client-Side Implementation

### Consumer Setup

Create a consumer connection (`app/javascript/channels/consumer.js`):

```javascript
import { createConsumer } from "@rails/actioncable";
export default createConsumer();
```

This connects to `/cable` by default. Specify a custom URL:

```javascript
createConsumer("wss://example.com/cable");
createConsumer("https://ws.example.com/cable");

// Dynamic URL generation
function getWebSocketURL() {
  const token = localStorage.get("auth-token");
  return `wss://example.com/cable?token=${token}`;
}
createConsumer(getWebSocketURL);
```

### Creating Subscriptions

Basic subscription:

```javascript
import consumer from "./consumer";

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" });
consumer.subscriptions.create({ channel: "AppearanceChannel" });
```

Multiple subscriptions to same channel:

```javascript
consumer.subscriptions.create({ channel: "ChatChannel", room: "1st Room" });
consumer.subscriptions.create({ channel: "ChatChannel", room: "2nd Room" });
```

### Subscription Lifecycle

Full subscription example with callbacks:

```javascript
import consumer from "./consumer";

consumer.subscriptions.create(
  { channel: "ChatChannel", room: "Best Room" },
  {
    // Called once when subscription is created
    initialized() {
      this.update = this.update.bind(this);
    },

    // Called when subscription is ready for use on the server
    connected() {
      this.install();
      this.update();
    },

    // Called when WebSocket connection is closed
    disconnected() {
      this.uninstall();
    },

    // Called when subscription is rejected by the server
    rejected() {
      this.uninstall();
    },

    // Called when data is received from the server
    received(data) {
      this.appendLine(data);
    },

    // Custom methods
    appendLine(data) {
      const html = this.createLine(data);
      const element = document.querySelector("[data-chat-room='Best Room']");
      element.insertAdjacentHTML("beforeend", html);
    },

    createLine(data) {
      return `
      <article class="chat-line">
        <span class="speaker">${data["sent_by"]}</span>
        <span class="body">${data["body"]}</span>
      </article>
    `;
    },
  }
);
```

### Sending Data from Client to Server

```javascript
const chatChannel = consumer.subscriptions.create(...)

// Send data to channel's receive method
chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." })

// Call channel methods (public methods exposed as RPCs)
chatChannel.perform("appear", { appearing_on: this.appearingOn })
chatChannel.perform("away")
```

### Client-Side Logging

Enable logging in browser console:

```javascript
import * as ActionCable from "@rails/actioncable";
ActionCable.logger.enabled = true;
```

---

## Full-Stack Examples

### Example 1: User Appearances (Presence Tracking)

**Server** (`app/channels/appearance_channel.rb`):

```ruby
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    current_user.appear
  end

  def unsubscribed
    current_user.disappear
  end

  def appear(data)
    current_user.appear(on: data["appearing_on"])
  end

  def away
    current_user.away
  end
end
```

**Client** (`app/javascript/channels/appearance_channel.js`):

```javascript
import consumer from "./consumer";

consumer.subscriptions.create("AppearanceChannel", {
  initialized() {
    this.update = this.update.bind(this);
  },

  connected() {
    this.install();
    this.update();
  },

  disconnected() {
    this.uninstall();
  },

  rejected() {
    this.uninstall();
  },

  update() {
    this.documentIsActive ? this.appear() : this.away();
  },

  appear() {
    this.perform("appear", { appearing_on: this.appearingOn });
  },

  away() {
    this.perform("away");
  },

  install() {
    window.addEventListener("focus", this.update);
    window.addEventListener("blur", this.update);
    document.addEventListener("turbo:load", this.update);
    document.addEventListener("visibilitychange", this.update);
  },

  uninstall() {
    window.removeEventListener("focus", this.update);
    window.removeEventListener("blur", this.update);
    document.removeEventListener("turbo:load", this.update);
    document.removeEventListener("visibilitychange", this.update);
  },

  get documentIsActive() {
    return document.visibilityState === "visible" && document.hasFocus();
  },

  get appearingOn() {
    const element = document.querySelector("[data-appearing-on]");
    return element ? element.getAttribute("data-appearing-on") : null;
  },
});
```

### Example 2: Web Notifications

**Server** (`app/channels/web_notifications_channel.rb`):

```ruby
class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

Broadcast from elsewhere:

```ruby
WebNotificationsChannel.broadcast_to(current_user,
  title: "New things!",
  body: "All the news fit to print"
)
```

**Client** (`app/javascript/channels/web_notifications_channel.js`):

```javascript
import consumer from "./consumer";

consumer.subscriptions.create("WebNotificationsChannel", {
  received(data) {
    new Notification(data["title"], { body: data["body"] });
  },
});
```

### Example 3: Rebroadcasting Messages

**Server**:

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end

  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:room]}", data)
  end
end
```

**Client**:

```javascript
const chatChannel = consumer.subscriptions.create(
  { channel: "ChatChannel", room: "Best Room" },
  {
    received(data) {
      /* handle */
    },
  }
);

chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." });
```

---

## Configuration

### Cable Configuration (`config/cable.yml`)

```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: redis
  url: redis://10.10.3.153:6381
  channel_prefix: appname_production
```

### Subscription Adapters

**Async Adapter**: Development/testing only. Processes messages within the same process. Does NOT work across multiple processes.

**Redis Adapter**: For production. Requires Redis server running.

```yaml
production:
  adapter: redis
  url: redis://10.10.3.153:6381
  channel_prefix: appname_production
  ssl_params:
    ca_file: "/path/to/ca.crt"
```

**PostgreSQL Adapter**: Uses Active Record connection pool for pub/sub. 8000 byte NOTIFY limit for large payloads.

**Solid Cable Adapter**: Database-backed using Active Record. Works with MySQL, SQLite, and PostgreSQL.

### Application Configuration (`config/application.rb` or environment files)

```ruby
# Mount path
config.action_cable.mount_path = "/websocket"

# Allowed request origins
config.action_cable.allowed_request_origins = [
  "https://rubyonrails.com",
  %r{http://ruby.*}
]

# Disable CSRF protection (development only)
config.action_cable.disable_request_forgery_protection = true

# Consumer URL
config.action_cable.url = "ws://localhost:28080"

# Worker pool size
config.action_cable.worker_pool_size = 4

# Log tags
config.action_cable.log_tags = [
  -> request { request.env["user_account_id"] || "no-account" },
  :action_cable,
  -> request { request.uuid }
]
```

### Layout Configuration

Add meta tag in layout HEAD:

```erb
<%= action_cable_meta_tag %>
```

This enables ActionCable.createConsumer() to connect properly.

---

## Running Action Cable

### In-Process (Development)

Runs alongside Rails application:

```ruby
config.action_cable.mount_path = "/websocket"
```

Specify consumer URL or rely on `action_cable_meta_tag`.

### Standalone Server (Production)

Create `cable/config.ru`:

```ruby
require_relative "../config/environment"
Rails.application.eager_load!
run ActionCable.server
```

Start the cable server:

```bash
bundle exec puma -p 28080 cable/config.ru
```

Configure Rails to use standalone server:

```ruby
# config/environments/production.rb
config.action_cable.mount_path = nil
config.action_cable.url = "wss://example.com/cable"
```

---

## Important Notes

**Database Connections**: For every server instance and worker spawned, you need a corresponding database connection. Default worker pool is 4, so require at least 4 connections in `config/database.yml`.

**Session Access**: WebSocket server doesn't have access to Rails session, but DOES have access to cookies. Use signed/encrypted cookies for authentication.

**Worker Pool**: Isolated from main server thread for connection callbacks and channel actions. Prevents blocking the server.

**Multi-threaded Servers**: Action Cable works with Unicorn, Puma, and Passenger through Rack socket hijacking API.

---

## Real-World Example: Live Comments App (from Repository)

The `rails/actioncable-examples` repository demonstrates a live comments feature:

**Setup Requirements**:

- Redis running on default port 6379
- Ruby 2.2.2+
- Rails 5.1+

**Key Components**:

1. **CommentsChannel** - Handles message comment subscriptions
2. **Connection** - Authenticates users via signed cookies
3. **Gemfile** - Includes redis, puma, turbolinks

**Key Files Structure**:

```
app/
  channels/
    application_cable/
      channel.rb
      connection.rb
    comments_channel.rb
  controllers/
  models/
  views/
  assets/
  jobs/
cable/
  config.ru
config/
  cable.yml
  database.yml
```

**Running the Example**:

```bash
./bin/setup
./bin/cable              # Terminal 1: Start cable server
./bin/rails server       # Terminal 2: Start web server
redis-server             # Terminal 3: Start Redis
```

Visit `http://localhost:3000` and open in two browser tabs to see live comments propagate in real-time.

---

## Implementation Workflow for Claude Code Agent

1. **Analyze Requirements**: Determine what real-time features are needed (presence, notifications, live updates)

2. **Set Up Connection**: Create/modify `app/channels/application_cable/connection.rb` with authentication logic

3. **Create Channels**: Generate channels with `rails generate channel ChannelName`

   - Implement `subscribed`, `unsubscribed`, and action methods
   - Use `stream_from` or `stream_for` to establish streaming

4. **Configure Broadcasting**:

   - Set `config/cable.yml` adapter (async for dev, redis for production)
   - Configure allowed origins in environment config

5. **Create Client Subscriptions**:

   - Build consumer imports in `app/javascript/channels/consumer.js`
   - Create channel subscription files with lifecycle callbacks
   - Implement `received()` method for handling data

6. **Implement Broadcasting**:

   - From controllers/jobs: `ChannelName.broadcast_to(model, data)` or `ActionCable.server.broadcast("stream", data)`
   - Ensure data serialization (typically JSON)

7. **Test Real-Time Features**:

   - Open multiple browser tabs
   - Verify subscriptions establish correctly
   - Test message propagation between clients
   - Verify disconnection handling

8. **Deploy Considerations**:
   - Use standalone server in production
   - Configure redis connection pooling
   - Set appropriate worker pool size based on concurrency needs
   - Verify cookie/authentication mechanism works with WebSocket

---

## References

- **Official Documentation**: https://guides.rubyonrails.org/action_cable_overview.html
- **Example Repository**: https://github.com/rails/actioncable-examples (archived 2023, but highly instructive)
- **Dependencies**: websocket-driver, nio4r, concurrent-ruby (Ruby side)
- **Testing**: Use `ActionCable::TestHelper` for comprehensive test coverage
