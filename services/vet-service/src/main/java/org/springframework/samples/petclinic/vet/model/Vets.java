package org.springframework.samples.petclinic.vet.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Vets implements Serializable {

    private List<Vet> vetList;

    public Vets() {
    }

    public Vets(List<Vet> vetList) {
        this.vetList = vetList;
    }

    public List<Vet> getVetList() {
        if (vetList == null) {
            vetList = new ArrayList<>();
        }
        return vetList;
    }

    public void setVetList(List<Vet> vetList) {
        this.vetList = vetList;
    }
}
