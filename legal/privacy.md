# Privacy Policy

**Vulpino**
Last updated: January 2025

---

## The Short Version

Vulpino doesn't collect your data. Everything stays on your device.

---

## What Vulpino Does

Vulpino fetches JSON data from URLs you provide and displays it in iOS widgets. That's it.

## Data Storage

**All data is stored locally on your device:**

- **Widget configurations** (URLs, selected fields, labels) are stored in your device's app storage
- **API keys and headers** are stored in your device's secure Keychain
- **Cached JSON responses** are stored locally for offline display

**We do not:**
- Collect or transmit your data to any server
- Track your usage or behavior
- Use analytics services
- Share data with third parties
- Have access to your API keys or the data you fetch

## Network Requests

When you add a widget, Vulpino makes HTTP requests to the URLs you specify. These requests:

- Go directly from your device to the endpoint you configured
- Include any headers you've added (like API keys)
- Include a `User-Agent: Vulpino/1.0` header identifying the app
- Are subject to a 1MB response size limit
- Are rate-limited to prevent accidental overload

**We never see these requests or responses.** They travel directly between your device and the servers you choose to connect to.

## Third-Party Services

Vulpino connects to whatever JSON endpoints you configure. We have no control over, and assume no responsibility for:

- The privacy practices of those services
- The accuracy or availability of their data
- How they handle requests from your device

Review the privacy policies of any services you connect to.

## Data Deletion

To delete all your data:

1. Open Vulpino
2. Tap the gear icon (Settings)
3. Tap "Manage Data"
4. Tap "Delete All Widgets"

Or simply delete the app—all data is removed with it.

## Children's Privacy

Vulpino does not knowingly collect information from children under 13. The app has no accounts, no data collection, and no social features.

## Changes to This Policy

If we update this policy, we'll post the new version here with an updated date. Continued use of the app after changes constitutes acceptance.

## Contact

Questions about this policy? Open an issue at:
https://github.com/ejfox/vulpino/issues

---

*Room 302 Studio*
