describe("model element handling", () => {
    let container;
    beforeEach(() => {
        container = document.createElement("div");
        document.body.appendChild(container);
    })
    afterEach(() => {
        container.remove();
    });

    it("basic model handling", () => {
        const element = document.createElement("test-components-helper-model-counter");
        container.appendChild(element);

        expect(element.shadowRoot.childNodes.length).toBe(3);
        expect(element.shadowRoot.childNodes[0].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[1].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[2].textContent).toBe("0");

        element.shadowRoot.childNodes[2].dispatchEvent(new Event("click"));

        expect(element.shadowRoot.childNodes[0].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[1].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[2].textContent).toBe("1");

        element.shadowRoot.childNodes[2].dispatchEvent(new Event("click"));

        expect(element.shadowRoot.childNodes[0].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[1].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[2].textContent).toBe("2");

        element.shadowRoot.childNodes[1].dispatchEvent(new Event("click"));

        expect(element.shadowRoot.childNodes[0].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[1].tagName).toBe("BUTTON");
        expect(element.shadowRoot.childNodes[2].textContent).toBe("1");
    });
});