// Reports to the page analytics, when the tracker has loaded. It may never:
// it's optional, and blocked in many browsers.
export const track = (name, data) => window.umami?.track(name, data)
