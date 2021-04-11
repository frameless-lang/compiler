describe("host element handling", () => {
    let container;
    beforeEach(() => {
       container = document.createElement("div");
       document.body.appendChild(container); 
    })
    afterEach(() => {
        container.remove();
    });

    it("basic text element creation", () => {
        const element = document.createElement("test-components-text-base-index");
        container.appendChild(element);

        expect(element.shadowRoot.childNodes.length).toBe(1);
        expect(element.shadowRoot.childNodes[0].textContent).toBe("foo");
    });
});